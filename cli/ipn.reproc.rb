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
    :name=>'clear', 
    :mandatory=>false, 
    :description=>'Delete all previous data about payments processing.', 
    :type=>BlackStack::SimpleCommandLineParser::BOOL,
    :default=>true,
  }, {
    :name=>'reproc', 
    :mandatory=>false, 
    :description=>'Reprocess the IPNs.', 
    :type=>BlackStack::SimpleCommandLineParser::BOOL,
    :default=>true,
=begin
  }, {
    :name=>'recalc', 
    :mandatory=>false, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::BOOL,
    :default=>true,
=end
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
=begin
      # verify if this client paid with the same PayPal account than other client
      self.logger.logs 'Check if the payer_email is not used by other client... '
      rows = DB[
        "select distinct x.id, x.name " +
        "from #{dname}..buffer_paypal_notification z " +
        "join #{dname}..invoice y on ( z.id=y.id_buffer_paypal_notification and y.id_client<>'#{c.id}' ) " +
        "join #{dname}..client x on x.id=y.id_client " +
        "where z.payer_email COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
        "  select distinct payer_email " +
        "  from kepler..buffer_paypal_notification " + 
        "  where item_number COLLATE SQL_Latin1_General_CP1_CI_AS in ( " + 
        "    select cast(id as varchar(500)) COLLATE SQL_Latin1_General_CP1_CI_AS " + 
        "    from #{dname}..invoice " +
        "    where id_client='#{c.id}' " + 
        "  ) " +
        ") "
      ].all
      if rows.size == 0
        self.logger.done
      else
        s = "ERROR: payer_email is used by other clients: "
        rows.each { |row| s += "#{row[:name]} (#{row[:id].to_guid}), " }
        s += '...'
        s += "Please reprocess these other clients before this one:\r\n"
        rows.each { |row| 
          s += 
          "ipn.reproc id_client=#{row[:id].to_guid}\r\n" + 
          "ipn.recalc id_client=#{row[:id].to_guid}\r\n" + 
          "ipn.expire id_client=#{row[:id].to_guid}\r\n"
        }        
        raise s
      end
=end
      # validar que no se tratade la division central
      self.logger.logs "Validate client's division is not the central... "
      raise 'Client assigned to central division' if d.central
      raise "Division #{dname} is known as the central division" if dname == 'kepler'
      self.logger.done

      self.logger.logs "Clear data... "
      if !PARSER.value('clear')
        self.logger.logf "It's disabled... "
      else
        # el cliente no puede estar habilitado para trial
        self.logger.logs 'Set trial off for the client... '
        DB.execute("update #{dname}..client set disabled_for_trial_ssm=1 where id='#{c.id}'")
        self.logger.done
  
        # delete movements that are not consumptions
        self.logger.logs 'Delete non-consumption movements... '
        DB[
          "select id " +
          "from #{dname}..movement with (nolock index(IX_movment__id_client__type)) " +
          "where id_client='#{c.id}' " +
          "and isnull([type],0)<>#{BlackStack::Movement::MOVEMENT_TYPE_CANCELATION.to_s}"
        ].all { |row|
          DB.execute("delete #{dname}..movement where id='#{row[:id]}'")
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
  
        # actualizo los amounts a 0
        self.logger.logs 'Update consumption movements with 0 amount, and 0 profits... '
        DB[
          "select id " +
          "from #{dname}..movement with (nolock index(IX_movment__id_client__type)) " +
          "where id_client='#{c.id}' "
        ].all { |row|
          DB.execute("update #{dname}..movement set amount=0, profits_amount=0 where id='#{row[:id]}'")
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
  
  			# delete invoice items of auto-generated invoices (invoices with a previous invoice)
        self.logger.logs 'Delete items of auto-generated invoices... '
        DB[
          "  select id " +
          "  from #{dname}..invoice " +
          "  where id_client='#{c.id}' " +
          "  and cast([id] as varchar(500)) not in ( " +
          "    select distinct item_number " +
          "    from kepler..buffer_paypal_notification " +
          "  ) "
        ].all { |row|
          DB.execute("delete #{dname}..invoice_item where id_invoice = '#{row[:id]}' ")
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
  			
        # delete auto-generated invoices (invoices with a previous invoice)
        self.logger.logs 'Delete auto-generated invoices... '
        DB[
          "select id " +
          "from #{dname}..invoice " + 
          "where id_client='#{c.id}' " +
          "and cast([id] as varchar(500)) not in ( " +
          "  select distinct item_number " +
          "  from kepler..buffer_paypal_notification " +
          ") "          
        ].all { |row|
          DB.execute("delete #{dname}..invoice where [id]='#{row[:id]}'")          
          DB.disconnect
          GC.start
          print '.'
        }
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

        DB[
          "select id " +
          "from #{dname}..invoice " + 
          "where id_client='#{c.id}' " +
          "and cast([id] as varchar(500)) in ( " +
          "  select distinct item_number " +
          "  from kepler..buffer_paypal_notification " +
          ") "          
        ].all { |row|
          DB.execute(
            "update #{dname}..invoice " + 
            "set " +
            "  subscr_id=null, " +
            "  status=#{BlackStack::Invoice::STATUS_UNPAID.to_s}, " +
            "  id_buffer_paypal_notification=null " +
            "where id='#{row[:id]}' "
          )
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
  
  			# delete subscriptions
        self.logger.logs 'Delete subscriptions... '
        DB["select id from #{dname}..paypal_subscription where id_client='#{c.id}'"].all { |row|
          DB.execute("delete #{dname}..paypal_subscription where id='#{row[:id]}'")          
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
=begin
# deprecated: the access point will check if the IPN already exists or not
#   
        # delete the IPNs in the division (NEVER in the central)
        self.logger.logs 'Delete IPNs in the division... '
        DB.execute(
          "delete #{dname}..buffer_paypal_notification where payer_email COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
          "  select distinct payer_email " +
          "  from kepler..buffer_paypal_notification " + 
          "  where item_number COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
          "    select cast(id as varchar(500)) COLLATE SQL_Latin1_General_CP1_CI_AS " +
          "    from #{dname}..invoice " +
          "    where id_client='#{c.id}' " +
          "  ) " +
          ") "
        )      
        self.logger.done
=end
        # update the IPNs in the central
        self.logger.logs 'Reset IPNs in the central... '
        DB[
          "select id " +
          "from kepler..buffer_paypal_notification " +
          "where payer_email in ( " +
          "  select distinct payer_email " + 
          "  from kepler..buffer_paypal_notification " + 
          "  where item_number in ( " +
          "    select cast(id as varchar(500)) " +
          "    from #{dname}..invoice " +
          "    where id_client='#{c.id}' " +
          "  ) " 
        ].all { |row|
          DB.execute(
            "update kepler..buffer_paypal_notification set " + 
            "  sync_reservation_id=null, " +
            "  sync_reservation_time=null, " +
            "  sync_reservation_times=null, " +
            "  sync_start_time=null, " +
            "  sync_end_time=null, " +
            "  sync_result=null where " +
            "id = '#{row[:id]}' " +
            ") "
          )
          DB.disconnect
          GC.start
          print '.'
        }
        self.logger.done
  
        self.logger.done
      end # if PARSER.value('clear')

      self.logger.logs 'Reprocessing... '
      if !PARSER.value('reproc')
        self.logger.logf "It's disabled"
      else
  			# reprocess all the IPNs in the central			
        DB["SELECT id FROM #{dname}..invoice where id_client='#{c.id}'"].all { |rowi|
          self.logger.logs "Process invoice #{rowi[:id]}... "
          BlackStack::BufferPayPalNotification.where(:invoice=>rowi[:id], :sync_end_time=>nil).order(:create_time).all { |p|
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

        self.logger.done
      end # if PARSER.value('reproc')
=begin
      # recalculate in the division
      self.logger.logs 'Recalculation... '
      if PARSER.value('recalc')
        BlackStack::InvoicingPaymentsProcessing::products_descriptor.each { |h|
          self.logger.logs "Product:#{h[:code]}... "
          c.recalculate(h[:code])
          self.logger.done
        }
        self.logger.done
      else
        self.logger.logf("it's disabled")
      end # if PARSER.value('recalc')
=end
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
