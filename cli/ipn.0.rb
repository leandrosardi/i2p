module IPNReprocessing
  def clear(c)
    # get the dvision name
    self.logger.logs 'Get the division name... '
    d = c.division.home
    dname = d.name
    self.logger.logf("done (#{dname})")
=begin
# TODO: add this validation to prevent abuses  
    # verify if this account paid with the same PayPal account than other account
    self.logger.logs 'Check if the payer_email is not used by other account... '
    rows = DB[
      "select distinct x.id, x.name " +
      "from #{dname}..buffer_paypal_notification z " +
      "join #{dname}..invoice y on ( z.id=y.id_buffer_paypal_notification and y.id_account<>'#{c.id}' ) " +
      "join #{dname}..account x on x.id=y.id_account " +
      "where z.payer_email COLLATE SQL_Latin1_General_CP1_CI_AS in ( " +
      "  select distinct payer_email " +
      "  from kepler..buffer_paypal_notification " + 
      "  where invoice COLLATE SQL_Latin1_General_CP1_CI_AS in ( " + 
      "    select cast(id as varchar(500)) COLLATE SQL_Latin1_General_CP1_CI_AS " + 
      "    from #{dname}..invoice " +
      "    where id_account='#{c.id}' " + 
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
        "ipn.reproc id_account=#{row[:id].to_guid}\r\n" + 
        "ipn.recalc id_account=#{row[:id].to_guid}\r\n" + 
        "ipn.expire id_account=#{row[:id].to_guid}\r\n"
      }        
      raise s
    end
=end

    # el cliente no puede estar habilitado para trial
    self.logger.logs 'Set trial off for the account... '
    DB.execute("update #{dname}..account set disabled_trial=1 where id='#{c.id}'")
    self.logger.done
  
    # delete movements that are not consumptions
    self.logger.logs 'Delete non-consumption movements... '
    DB[
      "select id " +
      "from #{dname}..movement with (nolock index(IX_movment__id_account__type)) " +
      "where id_account='#{c.id}' " +
      "and COALESCE([type],0)<>#{BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION.to_s}"
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
    q = "select id from #{dname}..movement with (nolock index(IX_movment__id_account__type)) where id_account='#{c.id}'"
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
      "  where i.id_account='#{c.id}' " +
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
      "where i.id_account='#{c.id}' " +
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
    DB[
      "select id " +
      "from #{dname}..invoice " + 
      "where id_account='#{c.id}' " #+
      #"and cast([id] as varchar(500)) in ( " +
      #"  select distinct invoice " +
      #"  from kepler..buffer_paypal_notification " +
      #") "          
    ].all { |row|
      DB.execute(
        "update #{dname}..invoice " + 
        "set " +
        "  subscr_id=null, " +
        "  status=#{BlackStack::I2P::Invoice::STATUS_UNPAID.to_s}, " +
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
    DB["select id from #{dname}..subscription where id_account='#{c.id}'"].all { |row|
      DB.execute("delete #{dname}..subscription where id='#{row[:id]}'")          
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
      "    where id_account='#{c.id}' " +
      "  ) " +
      ") "
    ].all { |row|
      DB.execute("UPDATE #{dname}..invoice SET id_buffer_paypal_notification=NULL WHERE id_buffer_paypal_notification='#{row[:id]}'");
      DB.execute("UPDATE #{dname}..subscription SET id_buffer_paypal_notification=NULL WHERE id_buffer_paypal_notification='#{row[:id]}'");
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
      "    where id_account='#{c.id}' " +
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
    DB["SELECT id FROM #{dname}..invoice where id_account='#{c.id}'"].all { |rowi|
      self.logger.logs "Process invoice #{rowi[:id]}... "
      BlackStack::I2P::BufferPayPalNotification.where("invoice like '%#{rowi[:id]}' and sync_end_time is null").order(:create_time).all { |p|
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
        res = BlackStack::Netting::call_post(url, params)          
        parsed = JSON.parse(res.body)
        if (parsed["status"] == "success")
          self.logger.logf("done (#{parsed.to_s})")
          p.sync_end_time = now()
          p.save()
        else
          raise "IPN #{p.id.to_guid} error:#{parsed.to_s}."
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
    BlackStack::I2P::services_descriptor.each { |h|
      self.logger.logs "Product:#{h[:code]}... "
      c.recalculate(h[:code])
      self.logger.done
    }
  end # def recalc

  def expire(c)
    c.movements.select { |m|
      (m.type == BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_PAYMENT || m.type == BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_BONUS) &&
      m.expiration_end_time.nil? &&
      m.expiration_tries.to_i < 3 &&
      !m.expiration_time.nil? &&
      m.expiration_lead_time < Time.now
    }.each { |m|
      self.logger.logs "#{m.id.to_guid}:#{m.service_code}:#{m.expiration_lead_time.to_s}:."       
      m.expire(m.expiration_lead_time, "Expiration of <a href='/settings/record?rid=#{m.id.to_guid}'>record:#{m.id.to_guid}</a> because the lead-time has been reached.") 
      self.logger.done
    }     
  end # def recalc
end # module
