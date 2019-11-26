require "simple_command_line_parser"
require "pampa_workers"
require_relative "../lib/invoicing_payments_processing"
require_relative './config'

# command line parameters 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will connect a division, and process an IPN already stored in the buffer_paypal_notification table.', 
  :configuration => [{
    :name=>'id', 
    :mandatory=>true, 
    :description=>'ID of the record in the table buffer_paypal_notification.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'name', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default=>DEFAULT_WORKER_NAME,
  }, {
    :name=>'division', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
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
    
    # process IPN
    begin
      # Depurar divisiones gemeals - Issue #976
      self.logger.logs 'Load division... '
      division = BlackStack::Division.where(:name=>PARSER.value('division')).first
      raise 'Division not found' if division.nil?
      self.logger.logf "done (#{division.name})"
  
      #
      self.logger.logs "Load IPN (#{PARSER.value('id')})... "
      p = BlackStack::BufferPayPalNotification.where(:id=>PARSER.value('id')).first
      raise 'IPN not found' if p.nil?
      self.logger.done
  
      # inicio la sincronizacion       
      self.logger.logs "Initialize IPN... "
      p.sync_result = nil
      p.sync_start_time = now()
      p.sync_end_time = nil
      p.save()
      self.logger.done

      self.logger.logs "Process IPN... "
      #BlackStack::BufferPayPalNotification.process(p.to_hash)
      BlackStack::Division.where("ISNULL(available,0)=1 AND ISNULL(home,0)=1 AND ISNULL(central,0)=0").all { |d|
        self.logger.logs "Division #{d.name}... "
        # obtengo el hash descriptor
        params = p.to_hash()
        # agrego el api-key al description
        params['api_key'] = BlackStack::Pampa::api_key 
        # envio la notificacion a la division
        url = "#{BlackStack::Pampa::api_protocol}://#{d.ws_url}:#{d.ws_port}/api1.3/accounting/sync/paypal/notification.json"
        #url = "http://#{d.ws_url}:87/api1.3/accounting/sync/paypal/notification.json"
        res = BlackStack::Netting::call_post(url, params)        
        parsed = JSON.parse(res.body)
        if (parsed["status"] == "success")
          self.logger.logf "Done"
          p.sync_end_time = now()
          p.save()
          # libero recursos
          DB.disconnect
          GC.start
          #
          break
        elsif ( parsed["status"] =~ /Invoice already exists/ ) #|| parsed["status"] =~ /Unknown item_number/ )
          self.logger.logf 'Invoice already exists'
          p.sync_end_time = now()
          p.save()
          # libero recursos
          DB.disconnect
          GC.start
          #
          break
        elsif parsed["status"] =~ /Client not found/
          self.logger.logf 'Client not found'
          
        elsif parsed["status"] =~ /Invoice not found/
          self.logger.logf 'Invoice not found'

        elsif parsed["status"] =~ /IPN already linked to an invoice/
          self.logger.logf 'IPN already linked to an invoice'

        else
          DB.execute("update buffer_paypal_notification set sync_result='Division: #{d.name}.<br/>#{"Error:#{parsed["status"]}. Description:#{parsed["description"]}".to_sql}<br/><br/>' where id='#{p.id}'")
          # libero recursos
          DB.disconnect
          GC.start
          # lanzo una excepcion
          raise "Error: #{parsed["status"]}"
          #
          #break
        end
      }

      # 
      self.logger.logs "Close IPN job... "
      p.sync_end_time = now()
      p.save()
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
