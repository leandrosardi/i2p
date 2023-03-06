# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'

# add required extensions
BlackStack::Extensions.append :i2p

l = BlackStack::LocalLogger.new('./movement.log')

while true
  i = 0

  begin
    BlackStack::I2P::Account.all { |a|
      l.logs "#{a.name}... "
      begin
        a.update_movements(l)
        a.update_balance
        l.done
      rescue => e
        l.logf "ERROR: #{e.message}"
      end
    }
  rescue => e
    l.logf "Error: #{e.message}"
  end 

  l.logs 'Sleeping... '
  if i == 0
    sleep(600)
    l.done
  else
    l.no
  end

end # while true