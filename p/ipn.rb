# load gem and connect database
require 'app/mysaas'
require 'app/lib/stubs'
require 'app/config'
require 'app/version'
DB = BlackStack::CRDB::connect
require 'app/lib/skeletons'
require 'app/extensions/i2p/lib/skeletons'

# add required extensions
BlackStack::Extensions.append :i2p

l = BlackStack::LocalLogger.new('./ipn.log')

# process pending IPNs
while true
  begin

    # restart failed IPNs
    l.logs "Restarting failed IPNs... "
    q = "
    select b.id --, b.sync_reservation_times, b.sync_result 
    from buffer_paypal_notification b 
    where b.sync_start_time is not null 
    and b.sync_end_time is null
    and coalesce(b.sync_reservation_times, 0) < 3
    order by b.create_time
    "
    i = 0
    DB[q].all { |row|
      i += 1
      id = row[:id]
      l.logs "Restarting IPN #{id}... "
      DB.execute("update buffer_paypal_notification set sync_start_time = null where id = '#{id}'")
      l.done
      # release
      DB.disconnect
      GC.start
      # break
      break if i > 100
    }
    l.done

    # iterate all exports with no start time, and a search.
    BlackStack::I2P::BufferPayPalNotification.where(:sync_start_time=>nil).order(:create_time).all.each do |ipn|
#BlackStack::I2P::BufferPayPalNotification.where(:id=>['d13527e4-58c5-4d83-94e1-6ab3848c291d']).all.each do |ipn|
      l.logs "Processing IPN #{ipn.id}"
      begin
          l.logs 'Flag start_time... '
          ipn.sync_start_time = now
          ipn.sync_reservation_times = ipn.sync_reservation_times.to_i + 1
          ipn.save
          l.done

          l.logs 'Sync IPN... '
          ipn.process
          l.done

          l.logs 'Flag end_time... '
          ipn.sync_end_time = now
          ipn.save
          l.done
      rescue => e
        l.logf "Error: #{e.message}"

        l.logs 'Flag error... '
        ipn.sync_result = e.message
        ipn.save
        l.done
      end
      l.done
    end # exports.each 
  rescue => e
    l.logf "Error: #{e.message}"
  end 

  l.logs 'Sleeping... '
  sleep(10)
  l.done

end # while true