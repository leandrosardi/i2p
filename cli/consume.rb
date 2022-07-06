#require "blackstack_commons"
#s = Time.now().to_s
#puts s
#t = DateTime.strptime(s, '%Y-%m-%d %H:%M:%S %Z').to_time
#puts t.to_s
#exit(0)

require "simple_command_line_parser"
require "pampa_workers"
require_relative "../lib/i2p"
require_relative './config'

# command line parameters 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'Create a movement about a payment received. If this payment is associated to a PayPal subscription, the command will create a new invoice for the next billing cycle too. This command will also run both recalculations and expiration of credits.', 
  :configuration => [{
    :name=>'id_account', 
    :mandatory=>true, 
    :description=>'ID of the account who is consuming credits.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'product', 
    :mandatory=>true,
    :description=>'Code of the product that is being consumed.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
		:default=>Time.now().to_s,
  }, {
    :name=>'credits', 
    :mandatory=>false,
    :description=>'Number of credits consumed.', 
    :type=>BlackStack::SimpleCommandLineParser::INT,
		:default=>1,
  }, {
    :name=>'date', 
    :mandatory=>false,
    :description=>'Consumption date-time with SQL format plus timezone (%Y-%m-%d). Example: 2020-07-23.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>Time.now().to_s,
  }, {
    :name=>'name', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>DEFAULT_WORKER_NAME,
  }, {
    :name=>'division', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too. The invoice cannot be already linked to another subscription.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>DEFAULT_DIVISION_NAME,
  }]
)

BlackStack::Pampa::set_division_name(
  PARSER.value('division')
)

# connect to DB and require ORM classes
require 'sequel'
#puts "Connector Descriptor: #{BlackStack::Pampa::connection_descriptor}"
DB = BlackStack::Pampa::db_connection
BlackStack::Pampa::require_db_classes
BlackStack::I2P::require_db_classes

# 
class MyCLIProcess < BlackStack::MyLocalProcess
  
  def process(argv)
    self.logger.log "Say hello to CLI for IPN manual processing!"
    
    self.logger.log "DB:#{DB['SELECT db_name() AS s'].first[:s]}."
    
    # process 
    begin
      # parse the date-time		
      s = PARSER.value('date')
#puts
#puts s
      t = DateTime.strptime(s, '%Y-%m-%d').to_time
#      t = Date.strptime(s, '%Y-%m-%d').to_time
#puts t.to_s
#puts

			# get the account
      self.logger.logs 'Get the account... '
			c = BlackStack::Client.where(:id=>PARSER.value('id_account')).first
      raise 'Client not found' if c.nil?
			self.logger.done
			
			# consume
      self.logger.logs 'Consume the credits... '
			i = 0
			while i<PARSER.value('credits').to_i
			 c.consume(PARSER.value('product'), 1, 'Consumption', t)
			 i+=1
			 print '.'
			end
			self.logger.done
			
    rescue => e
      self.logger.error(e)
    end

    # libero recursos
    self.logger.logs "Release resources... "
    DB.disconnect
    GC.start   
    self.logger.done

    self.logger.logs "Sleep for long time. Click CTRL+C to exit... "
    sleep(500000)
    self.logger.done

  end # process  
end # class

PROCESS = MyCLIProcess.new(PARSER.value('name'), PARSER.value('division'))
PROCESS.verify_configuration = false # disable this to run any script with the name of this worker-thread, even if worker is configured to run another script
PROCESS.run()
