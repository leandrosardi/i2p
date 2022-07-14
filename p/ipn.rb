# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'

puts '.'+BlackStack::I2P::plans_descriptor.to_s
exit(0)

# add required extensions
BlackStack::Extensions.append :i2p

l = BlackStack::LocalLogger.new('./ipn.log')

while true
  # iterate all exports with no start time, and a search.
  BlackStack::I2P::BufferPayPalNotification.where(:sync_start_time=>nil).all.each do |ipn|
    l.logs "Processing IPN #{ipn.id}"
    begin
        l.logs 'Flag start_time... '
        ipn.sync_start_time = now
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
      l.log "Error: #{e.message}"

      l.logs 'Flag error... '
      ipn.sync_result = e.message
      ipn.save
      l.done
    end
    l.done

  end # exports.each 

  l.logs 'Sleeping... '
  sleep(10)
  l.done

end # while true