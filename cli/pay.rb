#require "blackstack_commons"
#s = Time.now().to_s
#s = 
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
    :name=>'id_invoice', 
    :mandatory=>true, 
    :description=>'ID of the invoice related with this subscription. The invoice must be belong the same calient.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'date', 
    :mandatory=>false,
    :description=>'Payment date-time with SQL format plus timezone (%Y-%m-%d). Example: 2020-07-23.', 
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
			# get the invoice
      self.logger.logs 'Get the invoice... '
			i = BlackStack::I2P::Invoice.where(:id=>PARSER.value('id_invoice')).first
      raise 'Invoice not found' if i.nil?
			self.logger.done
			
      self.logger.logs 'Get the account... '
			c = i.account
			self.logger.done			
			
			# marco la factura como pagada
			# registro contable - bookkeeping
			if !i.canBePaid?
				raise 'Invoice cannot be paid'
			else
#puts
#puts "PARSER.value('date'):#{PARSER.value('date')}"
#puts
#s = "2020-07-24 18:15:00 -0300"
        s = PARSER.value('date')
				t = DateTime.strptime(s, '%Y-%m-%d').to_time
				i.getPaid(t)
    
				# TODO: code this!
				# i.recalculate
		
				# crea una factura para el periodo siguiente (dia, semana, mes, anio)
				j = BlackStack::I2P::Invoice.new()
				j.id = guid()
				j.id_account = c.id
				j.create_time = now()
				j.disabled_trial = c.disabled_trial
				j.save()
			
				# genero los datos de esta factura, como la siguiente factura a la que estoy pagando en este momento
				j.next(i)
			end
			
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
