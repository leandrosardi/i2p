require 'sequel'
require "simple_command_line_parser"
require "pampa_workers"
require_relative "../lib/invoicing_payments_processing"
require_relative './config'
require_relative './ipn.0.rb'

# command line parameters 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'Create a movement about a payment received. If this payment is associated to a PayPal subscription, the command will create a new invoice for the next billing cycle too. This command will also run both recalculations and expiration of credits.', 
  :configuration => [{
    :name=>'id_clients', 
    :mandatory=>true, 
    :description=>'ID of the client who is consuming credits.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'name', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>'dispatcher_kepler',
  }, {
    :name=>'division', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too. The invoice cannot be already linked to another subscription.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>'kepler', # central
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
  include IPNReprocessing

  def process(argv)
    self.logger.log "Say hello to CLI for IPN manual processing!"
    
    self.logger.log "DB:#{DB['SELECT db_name() AS s'].first[:s]}."
    
    # process 
    begin					
      PARSER.value('id_clients').split(/,/).each { |cid|
        # get the client
        self.logger.logs "Get the client #{cid.to_guid}... "
        c = BlackStack::Client.where(:id=>cid).first
        raise 'Client not found' if c.nil?
        self.logger.logf("done (#{c.name})");
  
        # get the dvision name
        self.logger.logs 'Get the division name... '
        d = c.division.home
        dname = d.name
        self.logger.logf("done (#{dname})")
    
        # validar que no se tratade la division central
        self.logger.logs "Validate client's division is not the central... "
        raise 'Client assigned to central division' if d.central
        raise "Division #{dname} is known as the central division" if dname == 'kepler'
        self.logger.done
      
        # 
        self.logger.logs 'Delete movements that are not consumption, invoices, and subscriptions...'
        self.clear(c)
        self.logger.done
        
        # 
        self.logger.logs 'Reprocess IPNs... '
        self.reproc(c)
        self.logger.done
=begin
        # 
        self.logger.logs 'Recalculate credits fees in the movement table... '
        self.recalc(c)
        self.logger.done
        
        # 
        self.logger.logs 'Expire unused credits in the movement table... '
        self.expire(c)
        self.logger.done
=end
        # update the table stat_balance
        self.logger.logs 'Update stat_balance... '
        c.update_stat_balance
        self.logger.done
      } # PARSER.value('id_clients').split(/,/).each	
    rescue => e
      self.logger.error(e)
    end

    # libero recursos
    self.logger.logs "Release resources... "
    DB.disconnect
    GC.start   
    self.logger.done

  end # process  
end # class

PROCESS = MyCLIProcess.new(PARSER.value('name'), PARSER.value('division'))
PROCESS.verify_configuration = false # disable this to run any script with the name of this worker-thread, even if worker is configured to run another script
PROCESS.run()
