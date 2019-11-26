module BlackStack
  class Movement < Sequel::Model(:movement)
    BlackStack::Movement.dataset = BlackStack::Movement.dataset.disable_insert_output
    self.dataset = self.dataset.disable_insert_output
  
    many_to_one :invoiceItem, :class=>:'BlackStack::InvoiceItem', :key=>:id_invoice_item
    many_to_one :client, :class=>:'BlackStack::Client', :key=>:id_client
  
    MOVEMENT_TYPE_ADD_PAYMENT = 0
    MOVEMENT_TYPE_ADD_BONUS = 1
    MOVEMENT_TYPE_REASSIGN_BALANCE = 2
    MOVEMENT_TYPE_REFUND_BALANCE = 3
    MOVEMENT_TYPE_CANCELATION = 4 # liability with the client is reduced due service delivery
    MOVEMENT_TYPE_EXPIRATION = 5 # liability with the client is reduced due credits expiration
  
    def typeName()
      if (self.type==MOVEMENT_TYPE_ADD_PAYMENT)
        return "Payment"
      elsif (self.type==MOVEMENT_TYPE_ADD_BONUS)
        return "Bonus"
      elsif (self.type==MOVEMENT_TYPE_REASSIGN_BALANCE)
        return "Reassignation"
      elsif (self.type==MOVEMENT_TYPE_REFUND_BALANCE)
        return "Refund"
      elsif (self.type==MOVEMENT_TYPE_CANCELATION)
        return "Service"
      elsif (self.type==MOVEMENT_TYPE_EXPIRATION)
        return "Expiration"
      end
    end
  
    def typeColorName()
      if (self.type==MOVEMENT_TYPE_ADD_PAYMENT)
        return "green"
      elsif (self.type==MOVEMENT_TYPE_ADD_BONUS)
        return "orange"
      elsif (self.type==MOVEMENT_TYPE_REASSIGN_BALANCE)
        return "black"
      elsif (self.type==MOVEMENT_TYPE_REFUND_BALANCE)
        return "red"
      elsif (self.type==MOVEMENT_TYPE_CANCELATION)
        return "blue"
      elsif (self.type==MOVEMENT_TYPE_EXPIRATION)
        return "blue"
      end
    end
    
    # actualiza el registro con los valores del item de una factura
    # type may be either MOVEMENT_TYPE_ADD_PAYMENT or MOVEMENT_TYPE_ADD_BONUS, but not other value
    def parse(item, type=MOVEMENT_TYPE_ADD_PAYMENT, description='n/a')
      plan = BlackStack::InvoicingPaymentsProcessing.plan_descriptor(item.item_number)
      prod = BlackStack::InvoicingPaymentsProcessing.product_descriptor(plan[:product_code])

      if (self.id==nil)
        self.id=guid()
      end
      self.id_client = item.invoice.id_client
      self.id_invoice_item = item.id
      self.create_time = item.invoice.billing_period_from
      self.type = type
      if (type != MOVEMENT_TYPE_ADD_BONUS)
        self.paypal1_amount = item.amount.to_f
        self.bonus_amount = 0
      else
        self.paypal1_amount = 0
        self.bonus_amount = item.amount.to_f
      end      
      self.amount = 0-item.amount.to_f
      self.credits = 0-item.units.to_i
      self.product_code = item.product_code
      self.profits_amount = 0
      self.description = description
      self.expiration_time = DB["SELECT DATEADD(#{prod[:credits_expiration_period].to_s}#{prod[:credits_expiration_period].to_s}, +#{prod[:credits_expiration_units].to_s}, GETDATE()) AS d"].first[:d].to_s    
      self.save()
    end

    # Creates a new record in the table movement, as an expiration of the unused credits of this movement.
    # This movement must be either a payment or a bonus.
    # This movement must have an expiration time.
    # The expiraton time of this movement is lower than the current date-time.
    def expire()
      m = self
      p = BlackStack::InvoicingPaymentsProcessing::product_descriptor(m.product_code)

      if m.type != MOVEMENT_TYPE_ADD_PAYMENT && m.type != MOVEMENT_TYPE_ADD_BONUS
        raise "Movement type mismatch."
      end

      if m.expiration_time.nil?
        raise "Expiration time is null."
      end

      if m.expiration_time >= Time::now()
        raise "Expiration time is pending."
      end

      if m.expiration_time <= m.create_time
        raise "Expiration time is lower then creation time."
      end
      
      # calculo cuantos creditos tiene este cliente
      #x = 0.to_f - BlackStack::Balance.new(m.client.id, p[:code]).credits.to_f
      # calculo los creditos de este movimiento que voy a cancelar
      x = 0.to_f - m.credits.to_f

      # calculo el credito consumido luego de este movimiento que voy a cancelar
      y = m.client.movements.select { |o| 
        o.credits.to_f > 0 &&
        o.product_code.upcase == p[:code].upcase && 
        o.create_time > m.create_time 
      }.inject(0) { |sum, o| sum.to_f + o.credits.to_f }.to_f

      # calculo el # de creditos no usados de este movimiento que ha expirado
      z = x-y>0 ? x-y : 0 

      # si el monto expirado es positivo, entonces registro
      # una cancelacion de saldo
      if z>0
        amount = ( m.amount.to_f / m.credits.to_f ) * z.to_f              
        m = BlackStack::Movement.new(
          :id_client => m.client.id,
          :create_time => now(),
          :type => BlackStack::Movement::MOVEMENT_TYPE_EXPIRATION,
          :description => "Expiration of #{m.id.to_guid}",
          :paypal1_amount => 0,
          :bonus_amount => 0,
          :amount => amount,
          :credits => z,
          :profits_amount => -amount,
          :product_code => p[:code],
        )
        m.id = guid()
        m.save
      end # z>0
    end # def expire
  end # class Movement
end # module BlackStack