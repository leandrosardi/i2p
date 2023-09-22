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

l = BlackStack::LocalLogger.new('./movement.log')

while true
  i = 0

  begin
    BlackStack::I2P::Account.all { |a|
      l.logs "#{a.name}... "
      begin
        a.update_balance_start_time = now
        a.save

        a.update_movements(l)
        a.update_balance
        l.done

        a.update_balance_success = true
        a.update_balance_end_time = now
        a.save

      rescue => e
        l.logf "ERROR: #{e.message}"

        a.update_balance_success = false
        a.update_balance_error_description = e.to_s
        a.save
      end
    }
  rescue => e
    l.logf "Error: #{e.message}"
  end 

  l.logs 'Sleeping... '
  if i == 0
    sleep(10)
    l.done
  else
    l.no
  end

end # while true