module BlackStack
  class Invoice < Sequel::Model(:invoice)
    STATUS_UNPAID = 0
    STATUS_PAID = 1
    STATUS_REFUNDED = 2
    PARAMS_FLOAT_MULTIPLICATION_FACTOR = 10000
  
    BlackStack::Invoice.dataset = BlackStack::Invoice.dataset.disable_insert_output
    self.dataset = self.dataset.disable_insert_output
  
    many_to_one :buffer_paypal_notification, :class=>:'BlackStack::BufferPayPalNotification', :key=>:id_buffer_paypal_notification
    many_to_one :client, :class=>:'BlackStack::Client', :key=>:id_client
    #many_to_one :paypal_subscription, :class=>:'BlackStack::PayPalSubscription', :key=>:id_paypal_subscription
		many_to_one :previous, :class=>:'BlackStack::Invoice', :key=>:id_previous_invoice
    one_to_many :items, :class=>:'BlackStack::InvoiceItem', :key=>:id_invoice
  
    def paypal_subscription
      return nil if self.subscr_id.nil?
      return nil if self.subscr_id.to_s.size == 0
      return BlackStack::PayPalSubscription.where(:subscr_id=>self.subscr_id.to_s).first
    end
  
    # compara 2 planes, y retorna TRUE si ambos pueden coexistir en una misma facutra, con un mismo enlace de PayPal
    def self.compatibility?(h, i)
      return false if h[:type]!=i[:type]
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:period]!=i[:period] 
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:units]!=i[:units] 
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:trial_period]!=i[:trial_period] 
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:trial_units]!=i[:trial_units] 
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:trial2_period]!=i[:trial2_period] 
      return false if h[:type]=='S' && h[:type]==i[:type] && h[:trial2_units]!=i[:trial2_units] 
      true
    end
  
    # retorna un array con la lista de estados posibles de una factura
    def self.statuses()
      [STATUS_UNPAID, STATUS_PAID, STATUS_REFUNDED]
    end
  
    # retorna un string con el nombre descriptivo del estado 
    def self.statusDescription(status)
      if status == STATUS_UNPAID || status == nil
        return "UNPAID"
      elsif status == STATUS_PAID
        return "PAID"
      elsif status == STATUS_REFUNDED
        return "REFUNDED"
      else
        raise "Unknown Invoice Status (#{status.to_s})"
      end
    end
  
    # retorna el valor del color HTML para un estado
    def self.statusColor(status)
      if status == STATUS_UNPAID || status == nil
        return "red"
      elsif status == STATUS_PAID
        return "green"
      elsif status == STATUS_REFUNDED
        return "brown"
      else
        raise "Unknown Invoice Status (#{status.to_s})"
      end
    end

    #
    def set_subscription(s)
      self.subscr_id = s.subscr_id
      self.delete_time = nil
      self.save
      # aplico la mismam modificacion a todas las factuas que le siguieron a esta
      BlackStack::Invoice.where(:id_previous_invoice=>self.id).all { |j|
        j.set_subscription(s)
        DB.disconnect
        GC.start
      }
    end

    # 
    def deserve_trial?
      return self.disabled_for_trial_ssm == false || self.disabled_for_trial_ssm == nil
    end
  
    # 
    def allowedToAddRemoveItems?
      return (self.status == STATUS_UNPAID || self.status == nil) && (self.disabled_for_add_remove_items == false || self.disabled_for_add_remove_items == nil)
    end
    
    # 
    def number()
      self.id.to_guid
    end
  
    # 
    def dateDesc()
      self.create_time.strftime('%b %d, %Y')
    end
  
    # 
    def dueDateDesc()
      Date.strptime(self.billing_period_from.to_s, '%Y-%m-%d').strftime('%b %d, %Y')
    end
  
    # 
    def billingPeriodFromDesc()
      Date.strptime(self.billing_period_from.to_s, '%Y-%m-%d').strftime('%b %d, %Y')
    end
  
    # 
    def billingPeriodToDesc()
      Date.strptime(self.billing_period_to.to_s, '%Y-%m-%d').strftime('%b %d, %Y')
    end
  
    # 
    def total()
      ret = 0
      self.items.each { |item|
        ret += item.amount.to_f
        # libero recursos
        DB.disconnect
        GC.start
      }
      ret
    end
  
    #
    def totalDesc()
      ("%.2f" % self.total.to_s)
    end
  
    # TODO: refactor me
    def paypal_link()
      item = self.items.first
      if item.nil?
        raise "Invoice has no items"      
      end
  
      plan_descriptor = self.client.plans.select { |j| j[:item_number].to_s == item.item_number.to_s }.first
      if plan_descriptor.nil?
        raise "Plan not found"      
      end
  
      product_descriptor = BlackStack::InvoicingPaymentsProcessing::products_descriptor.select { |j| j[:code].to_s == plan_descriptor[:product_code].to_s }.first
      if product_descriptor.nil?
        raise "Product not found"      
      end
  
      item_name = ""
      n = 0
      self.items.each { |t|
        h = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number].to_s == t.item_number.to_s }.first 
        item_name += '; ' if n>0
        item_name += h[:name]
        if item_name.size >= 65
          item_name += "..."
          break
        end
        n+=1
      }
  
      return_path = product_descriptor[:return_path]
      id_invoice = self.id
      id_client = self.client.id
      allow_trials = self.deserve_trial?
      
      bIsSubscription = false
      bIsSubscription = true if plan_descriptor[:type]=="S"
      
      # generating the invoice number
      invoice_id = "#{id_client.to_guid}.#{id_invoice.to_guid}"
    
      values = {}
      
      # common parameters for all the situations
      values[:business] = BlackStack::InvoicingPaymentsProcessing::paypal_business_email
      values[:lc] = "en_US"
      
      if bIsSubscription
        values[:cmd] = "_xclick-subscriptions"
      else
        values[:cmd] = "_xclick"
      end
      
      values[:upload] = 1
      values[:no_shipping] = 1
      values[:return] = BlackStack::Netting::add_param(return_path, "track_object_id", id_invoice.to_guid)
      values[:return_url] = BlackStack::Netting::add_param(return_path, "track_object_id", id_invoice.to_guid)
      values[:rm] = 1
      values[:notify_url] = BlackStack::InvoicingPaymentsProcessing::paypal_ipn_listener
      
      values[:invoice] = id_invoice
      values[:item_name] = item_name
      values[:item_number] = id_invoice.to_s
      values[:src] = '1'
    
      # si es una suscripcion
      if (bIsSubscription)

        trial1 = allow_trials && plan_descriptor[:trial_fee]!=nil && plan_descriptor[:trial_period]!=nil && plan_descriptor[:trial_units]!=nil
        trial2 = allow_trials && plan_descriptor[:trial2_fee]!=nil && plan_descriptor[:trial2_period]!=nil && plan_descriptor[:trial2_units]!=nil
        
        values[:a3] = 0
        self.items.each { |i|
          if trial1 && i.units!=i.plan_descriptor[:trial_credits]
            raise 'Cannot order more than 1 package and trial in the same invoice'
          elsif trial1
            values[:a3] += i.plan_descriptor[:fee].to_f
          else # !trial1
            values[:a3] += ( i.units.to_f * ( i.plan_descriptor[:fee].to_f / i.plan_descriptor[:credits].to_f ).to_f )
          end 
        }
        values[:p3] = plan_descriptor[:units] # every 1
        values[:t3] = plan_descriptor[:period] # per month
    
        # si tiene un primer periodo de prueba
        if trial1
          values[:a1] = 0 # $1 fee
          self.items.each { |i| values[:a1] += i.plan_descriptor[:trial_fee].to_i }
          values[:p1] = plan_descriptor[:trial_units] # 15
          values[:t1] = plan_descriptor[:trial_period] # days
    
          # si tiene un segundo periodo de prueba
          if trial2
            values[:a2] = 0 # $50 fee
            self.items.each { |i| values[:a2] += i.plan_descriptor[:trial2_fee].to_i }
            values[:p2] = plan_descriptor[:trial2_units] # first 1
            values[:t2] = plan_descriptor[:trial2_period] # month
          end
        end
    
      # sino, entonces es un pago por unica vez
      else
        values[:amount] = 0
        self.items.each { |i| values[:amount] += i.amount.to_f }         
      end
        
      # return url
      "#{BlackStack::InvoicingPaymentsProcessing::paypal_orders_url}/cgi-bin/webscr?" + URI.encode_www_form(values)
    end
  
    # retorna true si el estado de la factura sea NULL o UNPAID
    def canBePaid?
      self.status == nil || self.status == BlackStack::Invoice::STATUS_UNPAID
    end

    # retorna true si el estado de la factura sea NULL o UNPAID
    def canBeDeleted?
      if self.paypal_subscription.nil?
        return self.status == nil || self.status == BlackStack::Invoice::STATUS_UNPAID
      else # !self.paypal_subscription.nil?
        return (self.status == nil || self.status == BlackStack::Invoice::STATUS_UNPAID) && !self.paypal_subscription.active
      end # if self.paypal_subscription.nil?
    end
  
    # actualiza el registro en la tabla invoice segun los parametros. 
    # en este caso la factura se genera antes del pago.
    # genera el enlace de paypal.
    def setup()
      # busco el primer item de esta factura
      item = self.items.sort_by {|obj| obj.create_time}.first
      if item == nil
        raise "Invoice has no items."      
      end
      
      h = self.client.plans.select { |j| j[:item_number].to_s == item.item_number.to_s }.first
      if h == nil
        raise "Unknown item_number."
      end 
  
      # 
      return_path = h[:return_path]
  
      c = BlackStack::Client.where(:id=>id_client).first
      if (c==nil)
        raise "Client not found"
      end
  
      if (self.id == nil)
        self.id = guid()
      end
      self.create_time = now()
      self.id_client = c.id
      self.id_buffer_paypal_notification = nil
      self.paypal_url = self.paypal_link
  
      #
      self.save()
    end
  
    # Verifica que el estado de la factura sea NULL o UNPAID.
    # Cambia el estado de la factura de UNPAID a PAID.
    # Crea los registros contables por el pago de esta factura: un registro por cada item, y por cada bono del plan en cada item.
		# Los registros en la table de movimientos se registraran con la fecha del parametro sql_payment_datetime.
		# Las fechas de expiracion de los movimientos se calculan seguin la fecha del pago.
		# 
		# sql_payment_datetime: Fecha-hora del pago. Por defecto es la fecha-hora actual.
		# 
    def getPaid(payment_time=nil)
			payment_time = Time.now() if payment_time.nil?
		
      if self.canBePaid? == false
        raise "Method BlackStack::Invoice::getPaid requires the current status is nil or unpaid."
      end
      # marco la factura como pagada
      self.status = BlackStack::Invoice::STATUS_PAID
      self.delete_time = nil
      if self.previous.nil? # si es la primer factura de una suscripcion, o no es una suscripcion
        diff = payment_time.to_time - self.billing_period_from.to_time
        self.billing_period_from = payment_time
        self.billing_period_to = self.billing_period_to.to_time + diff
      end
      self.save
			# expiracion de creditos de la factura anterior
			i = self.previous
			if !i.nil?
				InvoiceItem.where(:id_invoice=>i.id).all { |item|
					# 
					BlackStack::Movement.where(:id_invoice_item => item.id).all { |mov|
						# 
						mov.expire(self.billing_period_from, "Expiration of <a href='/member/record?rid=#{mov.id.to_guid}'>record:#{mov.id.to_guid}</a> because subscription renewal.") if mov.expiration_on_next_payment == true
						#
						DB.disconnect
						GC.start
					} # BlackStack::Movement.where(:id_invoice_item => item.id).all { |mov|
					#
					DB.disconnect
					GC.start
				} # InvoiceItem.where(:id_invoice=>i.id).all { |item|
			end
      # registro los asientos contables
      InvoiceItem.where(:id_invoice=>self.id).all { |item|
				# obtengo descriptor del plan
				plan = BlackStack::InvoicingPaymentsProcessing.plan_descriptor(item.item_number)
				# obtengo descriptor del producto
				prod = BlackStack::InvoicingPaymentsProcessing.product_descriptor(plan[:product_code])
				# registro el pago
        BlackStack::Movement.new().parse(item, BlackStack::Movement::MOVEMENT_TYPE_ADD_PAYMENT, "Payment of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.", payment_time, item.id).save()
				# agrego los bonos de este plan
				if !plan[:bonus_plans].nil?
  				plan[:bonus_plans].each { |h|
  					plan_bonus = BlackStack::InvoicingPaymentsProcessing.plan_descriptor(h[:item_number])
  					raise "bonus plan not found" if plan_bonus.nil?					
  					bonus = BlackStack::InvoiceItem.new
  					bonus.id = guid()
  					bonus.id_invoice = self.id
  					bonus.product_code = plan_bonus[:product_code]
  					bonus.unit_price = 0
  					bonus.units = plan_bonus[:credits] * item.number_of_packages # agrego los creditos del bono, multiplicado por la cantiad de paquetes 
  					bonus.amount = 0
  					bonus.item_number = plan_bonus[:item_number]
  					BlackStack::Movement.new().parse(bonus, BlackStack::Movement::MOVEMENT_TYPE_ADD_BONUS, "Bonus from the <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.", payment_time, item.id).save()
  				}
        end # if !plan[:bonus_plans].nil?
        #
        DB.disconnect
        GC.start
      }
    end # def getPaid
  
    # Verify if I can add this item_number to this invoice.
    # Otherwise, it raise an exception.
    #
    # Si el atributo 'amount' ademas es distinto a nil, se filtran items por ese monto.
    # 
    def check_create_item(item_number, validate_items_compatibility=true, amount=nil)
      # busco el primer item de esta factura, si es que existe
      item0 = self.items.sort_by {|obj| obj.create_time}.first
  
      # encuentro el descriptor del plan
      # el descriptor del plan tambien es necesario para la llamada a paypal_link 
      h = self.client.plans.select { |j| j[:item_number].to_s == item_number.to_s }.first
      if h == nil
        raise "Unknown item_number"
      end 
  
      # returna true si el plan es una oferta one-time, 
      # => y ya existe una item de factura asignado a 
      # => este plan, con un importe igual al del trial1
      # => o trial2. 
      if h[:one_time_offer] == true
        if self.client.has_item(h[:item_number], amount) && h[:fee].to_f != amount.to_f
          raise "The plan is a one-time offer and you already have it included in an existing invoice"
        end
      end
          
      # si la factura ya tiene un item
      if !item0.nil?
        plan_descriptor = self.client.plans.select { |j| j[:item_number].to_s == item0.item_number.to_s }.first
        if plan_descriptor.nil?
          raise "Plan '#{item0.item_number.to_s}' not found"      
        end

        # valido que los items sean compatibles
        if !BlackStack::Invoice.compatibility?(h, plan_descriptor) && validate_items_compatibility==true
          raise "Incompatible Items"
        end
      end
    end

    # configura la factura, segun el importe que pagara el cliente, la configuracion del plan en el descriptor h, y si el clietne merece un trial o no 
    def create_item(item_number, n=1, validate_items_compatibility=true)      
      prev1 = self.previous
      prev2 = prev1.nil? ? nil : prev1.previous

      # encuentro el descriptor del plan
      # el descriptor del plan tambien es necesario para la llamada a paypal_link 
      h = self.client.plans.select { |j| j[:item_number].to_s == item_number.to_s }.first
  
      # mapeo variables
      amount = 0.to_f
      unit_price = 0.to_f
      units = 0.to_i
    
      # le seteo la fecha de hoy
      self.billing_period_from = now()
#puts
#puts  
      # si el plan tiene un primer trial, y
      # es la primer factura, entonces:
      # => se trata del primer pago por trial
      if h[:trial_fee] != nil && prev1.nil? && !self.disabled_for_trial_ssm
#puts 'a'
        units = h[:trial_credits].to_i
        unit_price = h[:trial_fee].to_f / h[:trial_credits].to_f
        billing_period_to = DB["SELECT DATEADD(#{h[:trial_period].to_s}, +#{h[:trial_units].to_s}, '#{self.billing_period_from.to_s}') AS [now]"].map(:now)[0].to_s

      # si el plan tiene un segundo trial, y
      # es la segunda factura, entonces:
      # => se trata del segundo pago por segundo trial
      elsif h[:trial2_fee] != nil && !prev1.nil? && prev2.nil?
#puts 'b'
        units = h[:trial2_credits].to_i
        unit_price = h[:trial2_fee].to_f / h[:trial2_credits].to_f
        billing_period_to = DB["SELECT DATEADD(#{h[:trial2_period].to_s}, +#{h[:trial2_units].to_s}, '#{self.billing_period_from.to_s}') AS [now]"].map(:now)[0].to_s

      # si el plan tiene un fee, y
      elsif h[:fee].to_f != nil && h[:type] == BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION
#puts 'c'
        units = n.to_i * h[:credits].to_i
        unit_price = h[:fee].to_f / h[:credits].to_f
        billing_period_to = DB["SELECT DATEADD(#{h[:period].to_s}, +#{h[:units].to_s}, '#{self.billing_period_from.to_s}') AS [now]"].map(:now)[0].to_s
  
      elsif h[:fee].to_f != nil && h[:type] == BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO
#puts 'd'
        units = n.to_i * h[:credits].to_i
        unit_price = h[:fee].to_f / h[:credits].to_f
        billing_period_to = billing_period_from
  
      else # se hace un prorrateo
        raise "Plan is specified wrong"
                
      end


      #
      amount = units.to_f * unit_price.to_f
  
      # valido si puedo agregar este item
      self.check_create_item(item_number, validate_items_compatibility, amount)
  
      # cuardo la factura en la base de datos
      self.billing_period_to = billing_period_to
      self.save()
  
      # creo el item por el producto LGB2
      item1 = BlackStack::InvoiceItem.new()
      item1.id = guid()
      item1.id_invoice = self.id
      item1.product_code = h[:product_code]
      item1.unit_price = unit_price.to_f
      item1.units = units.to_i
      item1.amount = amount.to_f
      item1.item_number = h[:item_number]
      item1.description = h[:name]   
      item1.detail = plan_payment_description(h)
  
      #
      return item1
    end
  
    def plan_payment_description(h)
      ret = ""
      ret += "$#{h[:trial_fee]} trial. " if self.deserve_trial? && !h[:trial_fee].nil?
      ret += "$#{h[:trial2_fee]} one-time price. " if self.deserve_trial? && !h[:trial2_fee].nil?
      ret += "$#{h[:fee]}/#{h[:period]}. " if h[:units].to_i <= 1 
      ret += "$#{h[:fee]}/#{h[:units]}#{h[:period]}. " if h[:units].to_i > 1 
      ret += "#{h[:credits]} credits. " if h[:credits].to_i > 1
      ret
    end
  
    # configura la factura, segun el importe que pagara el cliente, la configuracion del plan en el descriptor h, y si el clietne merece un trial o no 
    def add_item(item_number, n=1)
      # creo el item
      item1 = self.create_item(item_number, n)
      item1.save()
      
      # agrega el item al array de la factura
      self.items << item1
      
      # reconfiguro la factura
      self.setup()
    end # add_item
  
    def remove_item(item_id)
      DB.execute("DELETE invoice_item WHERE id_invoice='#{self.id}' AND [id]='#{item_id}'")
      self.setup
    end # remove_item
  
    # actualiza el registro en la tabla invoice como las siguiente factura. 
    # en este caso la factura se genera antes del pago.
    # crea uno o mas registros en la tabla invoice_item.
    def next(i)     
#      b = i.buffer_paypal_notification
#      if b == nil
#        raise "Method BlackStack::Invoice::next requires the previous invoice (i) is linked to a record in the table buffer_paypal_notification."
#      end
  
      id_client = i.id_client
      c = BlackStack::Client.where(:id=>id_client).first
      if c==nil
        raise "Client not found"
      end
      
      h = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number].to_s == i.items.first.item_number.to_s }.first
      if h==nil
        raise "Plan not found"
      end
  
      return_path = h[:return_path]
      
      if (self.id == nil)
        self.id = guid()
      end
      self.create_time = now()
      self.id_client = c.id
      self.id_buffer_paypal_notification = nil
			self.id_previous_invoice = i.id
      self.subscr_id = i.subscr_id 
      self.disabled_for_add_remove_items = true

      i.items.each { |t| 
        self.add_item(t.item_number, t.number_of_packages)
        #
        DB.disconnect
        GC.start 
      }
              
  
      self.billing_period_from = i.billing_period_to
      self.billing_period_to = DB["SELECT DATEADD(#{h[:period].to_s}, +#{h[:units].to_s}, '#{self.billing_period_from.to_s}') AS [now]"].map(:now)[0].to_s
  
      self.paypal_url = self.paypal_link
      self.paypal_url = nil if h[:type] == "S" # si se trata de una suscripcion, entonces esta factura se pagara automaticamente
      self.automatic_billing = 1 if h[:type] == "S" # si se trata de una suscripcion, entonces esta factura se pagara automaticamente
      self.save
    end
  
    # actualiza el registro en la tabla invoice segun un registro en la tabla buffer_paypal_notification.
    # en este caso la factura se genera despues del pago.
    # crea uno o mas registros en la tabla invoice_item.
    def parse(b)
      item_number = b.item_number
      payment_gross = b.payment_gross.to_f
      billing_from = b.create_time
      #isSubscription = b.isSubscription?
      c = b.get_client
      if (c==nil)
        raise "Client not found"
      end
      self.setup(item_number, c.id, payment_gross, billing_from)
    end # def parse(b)
  
    # Genera lis items de la factura de reembolso. 
    # payment_gross: es el tital reembolsado
    # id_invoice: es el ID de la factura que se está reembolsando
    #
    # Si el monto del reembolso es mayor al total de la factua, entocnes se levanta una excepcion
    #
    # Si existe un item, y solo uno, con importe igual al reembolso, entonces se aplica todo el reembolso a ese item. Y termina la funcion.
    # Si existen mas de un item con igual importe que el reembolso, entonces se levanta una excepcion.
    #
    # Si el monto del reembolso es igual al total de la factura, se hace un reembolso total de todos los items. Y termina la funcion.
    # Si la factura tiene un solo item, entonces se calcula un reembolso parcial.
    # Sino, entonces se levanta una excepcion.
    # 
    # TODO: Hacerlo transaccional
    def setup_refund(payment_gross, id_invoice)
      # cargo la factura
      i = BlackStack::Invoice.where(:id=>id_invoice).first    
      raise "Invoice not found (#{id_invoice})" if i.nil?
      # obtengo el total de la factura
      total = i.total.to_f
      # Si existe un item, y solo uno, con importe igual al reembolso, entonces se aplica todo el reembolso a ese item. Y termina la funcion.
      # Si existen mas de un item con igual importe que el reembolso, entonces se levanta una excepcion.
      matched_items = i.items.select { |o| o.amount.to_f == -payment_gross.to_f }
      # 
      if total < -payment_gross
        raise "The refund is higher than the invoice amount (invoice #{id_invoice}, #{total.to_s}, #{payment_gross.to_s})"
      # Si el monto del reembolso es igual al total de la factura, se hace un reembolso total de todos los items. Y termina la funcion.
      # Si el monto de la factura es distinto al moneto del reembolso, entonces se levanta una excepcion.
      elsif total == -payment_gross
        i.items.each { |u|
          h = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number] == u.item_number }.first
          raise "Plan not found" if h.nil?
          item1 = BlackStack::InvoiceItem.new()
          item1.id = guid()
          item1.id_invoice = self.id
          item1.unit_price = u.unit_price.to_f
          item1.units = -u.units
          item1.amount = -u.amount.to_f
          item1.product_code = u.product_code.to_s
          item1.item_number = u.item_number.to_s
          item1.detail = u.detail.to_s
          item1.description = u.description.to_s
          item1.save()
          # hago el reembolso de este item
          # si el balance quedo en negativo, entonces aplico otro ajuste
          BlackStack::Movement.new().parse(item1, BlackStack::Movement::MOVEMENT_TYPE_REFUND_BALANCE, "Full Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.").save()        
					net_amount = 0.to_f - BlackStack::Balance.new(self.client.id, u.product_code.to_s).amount.to_f
					net_credits = 0.to_f - BlackStack::Balance.new(self.client.id, u.product_code.to_s).credits.to_f
					if net_amount <= 0 && net_credits < 0
						adjust = self.client.adjustment(u.product_code.to_s, net_amount, net_credits, "Adjustment for Negative Balance After Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.")
						adjust.id_invoice_item = item1.id
						adjust.save			
					end # if net_amount < 0
          # hago el reembolso de cada bono de este item
          # si el balance quedo en negativo, entonces aplico otro ajuste
          h[:bonus_plans].each { |bonus|
            i = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number] == bonus[:item_number] }.first
            j = BlackStack::InvoicingPaymentsProcessing::products_descriptor.select { |obj| obj[:code] == i[:product_code] }.first
            item2 = BlackStack::InvoiceItem.new()
            item2.id = guid()
            item2.id_invoice = self.id
            item2.unit_price = 0
            item2.units = -i[:credits]
            item2.amount = 0
            item2.product_code = i[:product_code].to_s
            item2.item_number = i[:item_number].to_s
            item2.detail = 'Bonus Refund'
            item2.description = j[:description].to_s
            item2.save()
            BlackStack::Movement.new().parse(item2, BlackStack::Movement::MOVEMENT_TYPE_REFUND_BALANCE, "Bonus Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.").save()        
            net_amount = 0.to_f - BlackStack::Balance.new(self.client.id, i[:product_code].to_s).amount.to_f
            net_credits = 0.to_f - BlackStack::Balance.new(self.client.id, i[:product_code].to_s).credits.to_f
            if net_amount <= 0 && net_credits < 0
              adjust = self.client.adjustment(i[:product_code].to_s, net_amount, net_credits, "Adjustment for Negative Balance After Bonus Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.")
              adjust.id_invoice_item = item1.id
              adjust.save     
            end # if net_amount < 0            
          }
          # release resources
          DB.disconnect
          GC.start
        } # i.items.each { |u|
      # reembolso parcial de una factura con un unico item
      elsif i.items.size == 1 # and we know that: total < -payment_gross, so it is a partial refund
        t = i.items.first
				# 
        amount = -payment_gross.to_f
        unit_price = t.amount.to_f / t.units.to_f
        float_units = (amount / unit_price.to_f)
				units = float_units.round.to_i
				# 
        h = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number] == t.item_number }.first
        raise "Plan not found" if h.nil?
        item1 = BlackStack::InvoiceItem.new()
        item1.id = guid()
        item1.id_invoice = self.id
        item1.unit_price = unit_price.to_f
        item1.units = -units
        item1.amount = -amount.to_f
        item1.product_code = t.product_code.to_s
        item1.item_number = t.item_number.to_s
        item1.detail = t.detail.to_s
        item1.description = t.description.to_s
        item1.save()
        BlackStack::Movement.new().parse(item1, BlackStack::Movement::MOVEMENT_TYPE_REFUND_BALANCE, "Partial Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.").save()
				# agrego un ajuste por el redondeo a una cantidad entera de creditos
				if float_units.to_f != units.to_f
					adjustment_amount = unit_price.to_f * (units.to_f - float_units.to_f)
					adjust = self.client.adjustment(t.product_code.to_s, adjustment_amount, 0, "Adjustment for Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.", BlackStack::Movement::MOVEMENT_TYPE_REFUND_ADJUSTMENT)
					adjust.id_invoice_item = item1.id
					adjust.save
				end
				# si el balance quedo en negativo, entonces aplico otro ajuste
				net_amount = 0.to_f - BlackStack::Balance.new(self.client.id, t.product_code.to_s).amount.to_f
				net_credits = 0.to_f - BlackStack::Balance.new(self.client.id, t.product_code.to_s).credits.to_f
				if net_amount < 0 && net_credits < 0
					adjust = self.client.adjustment(t.product_code.to_s, net_amount, net_credits, "Adjustment for Negative Balance After Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.")
					adjust.id_invoice_item = item1.id
					adjust.save			
				end # if net_amount < 0
				
				# recalculo todos los consumos y expiraciones - CANCELADO - Debe hacerse offline
				# => self.client.recalculate(t.product_code.to_s)
				
        # si el cliente se quedo sin saldo luego del reembolso parcial 
        if net_amount <= 0
          # hago el reembolso de cada bono de este item
          # si el balance quedo en negativo, entonces aplico otro ajuste
          h[:bonus_plans].each { |bonus|
            i = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number] == bonus[:item_number] }.first
            j = BlackStack::InvoicingPaymentsProcessing::products_descriptor.select { |obj| obj[:code] == i[:product_code] }.first
            item2 = BlackStack::InvoiceItem.new()
            item2.id = guid()
            item2.id_invoice = self.id
            item2.unit_price = 0
            item2.units = -i[:credits]
            item2.amount = 0
            item2.product_code = i[:product_code].to_s
            item2.item_number = i[:item_number].to_s
            item2.detail = 'Bonus Refund'
            item2.description = j[:description].to_s
            item2.save()
            BlackStack::Movement.new().parse(item2, BlackStack::Movement::MOVEMENT_TYPE_REFUND_BALANCE, "Bonus Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.").save()        
            net_amount = 0.to_f - BlackStack::Balance.new(self.client.id, i[:product_code].to_s).amount.to_f
            net_credits = 0.to_f - BlackStack::Balance.new(self.client.id, i[:product_code].to_s).credits.to_f
            if net_amount <= 0 && net_credits < 0
              adjust = self.client.adjustment(i[:product_code].to_s, net_amount, net_credits, "Adjustment for Negative Balance After Bonus Refund of <a href='/member/invoice?iid=#{self.id.to_guid}'>invoice:#{self.id.to_guid}</a>.")
              adjust.id_invoice_item = item1.id
              adjust.save     
            end # if net_amount < 0            
          }
        end
      else # we know that: i.items.size > 1 && total < -payment_gross
        raise "Refund amount is not matching with the invoice total (#{total.to_s}) and the invoice has more than 1 item."
      end
      # release resources
      DB.disconnect
      GC.start
    end # def setup_refund

    def refund(amount)
      c = self.client
      # creo la factura por el reembolso
      j = BlackStack::Invoice.new()
      j.id = guid()
      j.id_client = c.id
      j.create_time = now()
      j.disabled_for_trial_ssm = c.disabled_for_trial_ssm
      j.id_buffer_paypal_notification = nil
      j.status = BlackStack::Invoice::STATUS_REFUNDED
      j.billing_period_from = self.billing_period_from
      j.billing_period_to = self.billing_period_to
      j.paypal_url = nil
      j.disabled_for_add_remove_items = true
      j.subscr_id = self.subscr_id
      j.id_previous_invoice = self.id
      j.save()
            
      # parseo el reeembolso - creo el registro contable
      j.setup_refund(amount, self.id)
    end # refund

  end # class Invoice
end # module BlackStack 