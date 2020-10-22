#require "blackstack_commons"
#s = Time.now().to_s
#puts s
#t = DateTime.strptime(s, '%Y-%m-%d %H:%M:%S %Z').to_time
#puts t.to_s
#exit(0)

require "simple_command_line_parser"
require "pampa_workers"
require_relative "../lib/invoicing_payments_processing"
require_relative './config'

# command line parameters 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'Create a movement about a payment received. If this payment is associated to a PayPal subscription, the command will create a new invoice for the next billing cycle too. This command will also run both recalculations and expiration of credits.', 
  :configuration => [{
    :name=>'id_client', 
    :mandatory=>true, 
    :description=>'ID of the client who is consuming credits.', 
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

      # get the dvision name
      self.logger.logs 'Get the division name... '
      d = c.division
      dname = d.name
      self.logger.logf("done (#{dname})")

      # validar que no se tratade la division central
      self.logger.logs "Validate client's division is not the central... "
      raise 'Client assigned to central division' if d.central
      raise "Division #{dname} is known as the central division" if dname == 'kepler'
      self.logger.done

      # el cliente no puede estar habilitado para trial
      self.logger.logs 'Set trial off for the client... '
      DB.execute("update #{dname}..client set disabled_for_trial_ssm=1 where id='#{c.id}'")
      self.logger.done

      # delete movements that are not consumptions
      self.logger.logs 'Delete non-consumption movements... '
      DB.execute("delete #{dname}..movement where id_client='#{c.id}' and isnull([type],0)<>#{BlackStack::Movement::MOVEMENT_TYPE_CANCELATION.to_s}")
      self.logger.done

      # actualizo los amounts a 0
      self.logger.logs 'Update consumption movements with 0 amount, and 0 profits... '
      DB.execute("update #{dname}..movement set amount=0, profits_amount=0 where id_client='#{c.id}'")
      self.logger.done

			# delete invoice items of auto-generated invoices (invoices with a previous invoice)
      self.logger.logs 'Delete items of auto-generated invoices... '
      DB.execute(
        "delete #{dname}..invoice_item where id_invoice in (" +
        "  select id " +
        "  from #{dname}..invoice " +
        "  where id_client='#{c.id}' " +
        "  and cast([id] as varchar(500)) not in ( " +
        "    select distinct item_number " +
        "    from kepler..buffer_paypal_notification " +
        "  ) " +
        ") "
      )
      self.logger.done
			
      # delete auto-generated invoices (invoices with a previous invoice)
      self.logger.logs 'Delete auto-generated invoices... '
      DB.execute(
        "delete #{dname}..invoice " + 
        "where id_client='#{c.id}' " +
        "and cast([id] as varchar(500)) not in ( " +
        "  select distinct item_number " +
        "  from kepler..buffer_paypal_notification " +
        ") "
      )
      self.logger.done
			
      # actualizar estado de factoras a UNPAID, 
      # desvincularlas de cualquier subscripcion,
      # desvincularlas de cualquie IPN 
      self.logger.logs 'Update invoices to unpaid status, unlink to any IPN, unlink to any subscription... '
      DB.execute(
        "update #{dname}..invoice " + 
        "set " +
        "  subscr_id=null, " +
        "  status=#{BlackStack::Invoice::STATUS_UNPAID.to_s}, " +
        "  id_buffer_paypal_notification=null " +
        "where id_client='#{c.id}' " +
        "and cast([id] as varchar(500)) in ( " +
        "  select distinct item_number " +
        "  from kepler..buffer_paypal_notification " +
        ") "
      )
      self.logger.done

			# delete subscriptions
      self.logger.logs 'Delete subscriptions... '
      DB.execute("delete #{dname}..paypal_subscription where id_client='#{c.id}'")
      self.logger.done

      # delete the IPNs in the division (NEVER in the central)
      self.logger.logs 'Delete IPNs in the division... '
      DB.execute(
        "delete #{dname}..buffer_paypal_notification where payer_email in ( " +
        "  select distinct payer_email " +
        "  from kepler..buffer_paypal_notification " + 
        "  where item_number in ( " +
        "    select cast(id as varchar(500)) " +
        "    from #{dname}..invoice " +
        "    where id_client='#{c.id}' " +
        "  ) " +
        ") "
      )      
      self.logger.done

      # update the IPNs in the central
      self.logger.logs 'Reset IPNs in the central... '
      DB.execute(
        "update kepler..buffer_paypal_notification set " + 
        "  sync_reservation_id=null, " +
        "  sync_reservation_time=null, " +
        "  sync_reservation_times=null, " +
        "  sync_start_time=null, " +
        "  sync_end_time=null, " +
        "  sync_result=null where " +
        "payer_email in ( " +
        "  select distinct payer_email " + 
        "  from kepler..buffer_paypal_notification " + 
        "  where item_number in ( " +
        "    select cast(id as varchar(500)) " +
        "    from #{dname}..invoice " +
        "    where id_client='#{c.id}' " +
        "  ) " +
        ") "
      )
      self.logger.done

			# reprocess all the IPNs in the central			
      DB["SELECT id FROM #{dname}..invoice where id_client='#{c.id}'"].all { |rowi|
        self.logger.logs "Process invoice #{rowi[:id]}... "
        BlackStack::BufferPayPalNotification.where(:invoice=>rowi[:id]).order(:create_time).all { |p|
          self.logger.logs "IPN #{p.id.to_guid}... "
          
          # inicio la sincronizacion.
          self.logger.logs "Initialize IPN... "
          p.sync_result = nil
          p.sync_start_time = now()
          p.sync_end_time = nil
          p.save()
          self.logger.done
          
          # IPN to hash
          self.logger.logs "Get IPN hash... "
          params = p.to_hash()
          self.logger.done
          
          # agrego el api-key al descriptor
          self.logger.logs "Get API-KEY... "
          params['api_key'] = BlackStack::Pampa::api_key 
          self.logger.done

          # armo la URL a los access points
          # envio la notificacion a la division
          self.logger.logs "Submit... "
          api_url = "#{BlackStack::Pampa::api_protocol}://#{d.ws_url}:#{d.ws_port}"
          url = "#{api_url}/api1.3/accounting/sync/paypal/notification.json"
          res = BlackStack::Netting::call_post(url, params)          
          parsed = JSON.parse(res.body)
          if (parsed["status"] == "success")
            self.logger.done
            p.sync_end_time = now()
            p.save()
          else
            raise "IPN submission error:#{parsed['status']}."
          end

          # done
          self.logger.done

          # release resources
          DB.disconnect
          GC.start
        }
        self.logger.done
      }
			
			# recalculate in the division
      self.logger.logs 'Recalculation... '
      BlackStack::InvoicingPaymentsProcessing::products_descriptor.each { |h|
        self.logger.logs "Product:#{h[:code]}... "
        c.recalculate(h[:code])
        self.logger.done
      }
      self.logger.done
			
			# CANCELED: run expirations in the division -> It's done in p/_jobs.rb 
			
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
