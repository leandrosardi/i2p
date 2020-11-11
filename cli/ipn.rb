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
  
  def clear(c)
    # get the dvision name
    self.logger.logs 'Get the division name... '
    d = c.division.home
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
      "  where invoice COLLATE SQL_Latin1_General_CP1_CI_AS in ( " + 
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
    a = []
    q = "select id from #{dname}..movement with (nolock index(IX_movment__id_client__type)) where id_client='#{c.id}'"
    DB[q].all { |row|
      a << row[:id].to_guid
      if a.size % 100 == 0          
        DB.execute("update #{dname}..movement set amount=0, profits_amount=0 where id in ('#{a.join("','")}')") if a.size > 0
        a.clear
        DB.disconnect
        GC.start
        print '.' 
      end
    }
    DB.execute("update #{dname}..movement set amount=0, profits_amount=0 where id in ('#{a.join("','")}')") if a.size > 0 # actualizo el resto que pudo quedar en el array
    self.logger.done #logf("done (#{DB[q].all.size.to_s} remaining)")
  
    # delete invoice items of auto-generated invoices (invoices with a previous invoice)
    self.logger.logs 'Delete items of auto-generated invoices, set id_previous_invoice to null... '
    DB[
      "  select i.id " +
      "  from #{dname}..invoice i " +
      "  where i.id_client='#{c.id}' " +
      "  and not exists ( " +
      "    select distinct b.invoice " +
      "    from kepler..buffer_paypal_notification b " +
      "    where lower(b.invoice) like '%'+lower(cast(i.[id] as varchar(500)))+'%' " +
      "  ) "
    ].all { |row|
      DB.execute("delete #{dname}..invoice_item where id_invoice = '#{row[:id]}' ")
      DB.execute("update #{dname}..invoice set id_previous_invoice=null where id_previous_invoice = '#{row[:id]}' ")
      DB.disconnect
      GC.start
      print '.'
    }
    self.logger.done
        
    # delete auto-generated invoices (invoices with a previous invoice)
    self.logger.logs 'Delete auto-generated invoices... '
    DB[
      "select i.id " +
      "from #{dname}..invoice i " + 
      "where i.id_client='#{c.id}' " +
      "and not exists ( " +
      "  select distinct b.invoice " +
      "  from kepler..buffer_paypal_notification b " +
      "  where lower(b.invoice) like '%'+lower(cast(i.[id] as varchar(500)))+'%' " +
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
=begin
    DB.execute(
      "update #{dname}..invoice " + 
      "set " +
      "  subscr_id=null, " +
      "  status=#{BlackStack::Invoice::STATUS_UNPAID.to_s}, " +
      "  id_buffer_paypal_notification=null " +
      "where id_client='#{c.id}' " #+
      #"and cast([id] as varchar(500)) in ( " +
      #"  select distinct invoice " +
      #"  from kepler..buffer_paypal_notification " +
      #") "
    )
=end
    DB[
      "select id " +
      "from #{dname}..invoice " + 
      "where id_client='#{c.id}' " #+
      #"and cast([id] as varchar(500)) in ( " +
      #"  select distinct invoice " +
      #"  from kepler..buffer_paypal_notification " +
      #") "          
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

    # delete the IPNs in the division (NEVER in the central)
    self.logger.logs 'Delete IPNs in the division... '
    DB[
      "SELECT id FROM #{dname}..buffer_paypal_notification where payer_email COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
      "  select distinct payer_email " +
      "  from kepler..buffer_paypal_notification " + 
      "  where invoice COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
      "    select cast(id as varchar(500)) COLLATE SQL_Latin1_General_CP1_CI_AS " +
      "    from #{dname}..invoice " +
      "    where id_client='#{c.id}' " +
      "  ) " +
      ") "
    ].all { |row|
      DB.execute("UPDATE #{dname}..invoice SET id_buffer_paypal_notification=NULL WHERE id_buffer_paypal_notification='#{row[:id]}'");
      DB.execute("UPDATE #{dname}..paypal_subscription SET id_buffer_paypal_notification=NULL WHERE id_buffer_paypal_notification='#{row[:id]}'");
      DB.execute("DELETE #{dname}..buffer_paypal_notification WHERE [id]='#{row[:id]}'");
      DB.disconnect
      GC.start
    }
    self.logger.done

    # update the IPNs in the central
    self.logger.logs 'Reset IPNs in the central... '
    DB[
      "select id " +
      "from kepler..buffer_paypal_notification b " +
      "where b.payer_email in ( " +
      "  select distinct c.payer_email " + 
      "  from kepler..buffer_paypal_notification c " + 
      "  where exists ( " +
      "    select cast(i.id as varchar(500)) " +
      "    from #{dname}..invoice i " +
      "    where id_client='#{c.id}' " +
      "    and lower(c.invoice) like '%'+lower(cast(i.id as varchar(500)))+'%' " +
      "  ) " +
      ") "
    ].all { |row|
      DB.execute(
        "update kepler..buffer_paypal_notification set " + 
        "  sync_reservation_id=null, " +
        "  sync_reservation_time=null, " +
        "  sync_reservation_times=null, " +
        "  sync_start_time=null, " +
        "  sync_end_time=null, " +
        "  sync_result=null where " +
        "id = '#{row[:id]}' "
      )
      DB.disconnect
      GC.start
      print '.'
    }
    self.logger.done
  end # def clear

  def reproc(c)
    # get the dvision name
    self.logger.logs 'Get the division name... '
    d = c.division.home
    dname = d.name
    self.logger.logf("done (#{dname})")

    # reprocess all the IPNs in the central     
    DB["SELECT id FROM #{dname}..invoice where id_client='#{c.id}'"].all { |rowi|
      self.logger.logs "Process invoice #{rowi[:id]}... "
      BlackStack::BufferPayPalNotification.where("invoice like '%#{rowi[:id]}' and sync_end_time is null").order(:create_time).all { |p|
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
api_url = "http://74.208.28.38:81"
        url = "#{api_url}/api1.3/accounting/sync/paypal/notification.json"
#puts
#puts "url:#{url}:."
#puts "params:#{params}:."
        res = BlackStack::Netting::call_post(url, params)          
        parsed = JSON.parse(res.body)
        if (parsed["status"] == "success")
          self.logger.logf("done (#{parsed.to_s})")
          p.sync_end_time = now()
          p.save()
        else
          raise "IPN submission error:#{parsed.to_s}."
        end  
        self.logger.done

        # release resources
        DB.disconnect
        GC.start
      }
      self.logger.done
    }
  end # def reproc

  def recalc(c)
    BlackStack::InvoicingPaymentsProcessing::products_descriptor.each { |h|
      self.logger.logs "Product:#{h[:code]}... "
      c.recalculate(h[:code])
      self.logger.done
    }
  end # def recalc

  def expire(c)
    c.movements.select { |m|
      (m.type == BlackStack::Movement::MOVEMENT_TYPE_ADD_PAYMENT || m.type == BlackStack::Movement::MOVEMENT_TYPE_ADD_BONUS) &&
      m.expiration_end_time.nil? &&
      m.expiration_tries.to_i < 3 &&
      !m.expiration_time.nil? &&
      m.expiration_lead_time < Time.now
    }.each { |m|
      self.logger.logs "#{m.id.to_guid}:#{m.product_code}:#{m.expiration_lead_time.to_s}:."       
      m.expire(m.expiration_lead_time, "Expiration of <a href='/member/record?rid=#{m.id.to_guid}'>record:#{m.id.to_guid}</a> because the lead-time has been reached.") 
      self.logger.done
    }     
  end # def recalc

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
        
        # 
        self.logger.logs 'Recalculate credits fees in the movement table... '
        self.recalc(c)
        self.logger.done
        
        # 
        self.logger.logs 'Expire unused credits in the movement table... '
        self.expire(c)
        self.logger.done

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

    self.logger.logs "Sleep for long time. Click CTRL+C to exit... "
    sleep(500000)
    self.logger.done

  end # process  
end # class

PROCESS = MyCLIProcess.new(PARSER.value('name'), PARSER.value('division'))
PROCESS.verify_configuration = false # disable this to run any script with the name of this worker-thread, even if worker is configured to run another script
PROCESS.run()
