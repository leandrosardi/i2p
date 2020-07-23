require "simple_command_line_parser"
require "pampa_workers"
require_relative "../lib/invoicing_payments_processing"
require_relative './config'

# command line parameters 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'Register a new PayPal subscription.', 
  :configuration => [{
    :name=>'id_client', 
    :mandatory=>true, 
    :description=>'ID of the client owner of the subscription.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'id_invoice', 
    :mandatory=>true, 
    :description=>'ID of the invoice related with this subscription. The invoice must be belong the same calient.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'code', 
    :mandatory=>true, 
    :description=>'Code of the new subscription.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>DEFAULT_WORKER_NAME,
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
BlackStack::InvoicingPaymentsProcessing::require_db_classes

# 
class MyCLIProcess < BlackStack::MyLocalProcess
  
  def process(argv)
    self.logger.log "Say hello to CLI for IPN manual processing!"
    
    self.logger.log "DB:#{DB['SELECT db_name() AS s'].first[:s]}."
    
    # process 
    begin		
			# get the client
      self.logger.logs 'Get the client... '
			c = BlackStack::Client.where(:id=>PARSER.value('id_client')).first
      raise 'Client not found' if c.nil?
			self.logger.done

			# get the invoice
      self.logger.logs 'Get the client... '
			i = BlackStack::Invoice.where(:id=>PARSER.value('id_invoice')).first
      raise 'Invoice not found' if i.nil?
      raise 'Invoice is beling another client' if i.id_client.to_guid != c.id.to_guid
			raise 'Invoice already linked to another subscription' if !i.subscr_id.nil?
			self.logger.done
			
			# create the subscription
      self.logger.logs 'Create subscription... '
			s = BlackStack::PayPalSubscription.new
			s.id = guid()
			s.subscr_id = PARSER.value('code')
			s.id_buffer_paypal_notification = nil
			s.create_time = now
			s.id_client = c.id
			s.active = true
			s.save
			self.logger.done

      self.logger.logs 'Update invoice... '
			i.subscr_id = PARSER.value('code')
			i.save
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
