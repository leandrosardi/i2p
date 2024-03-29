module BlackStack
  module I2P
    class Movement < Sequel::Model(:movement)    
      many_to_one :invoiceItem, :class=>:'BlackStack::I2P::InvoiceItem', :key=>:id_invoice_item
      many_to_one :account, :class=>:'BlackStack::I2P::Account', :key=>:id_account
    
      MOVEMENT_TYPE_ADD_PAYMENT = 0
      MOVEMENT_TYPE_ADD_BONUS = 1
      MOVEMENT_TYPE_REASSIGN_BALANCE = 2
      MOVEMENT_TYPE_REFUND_BALANCE = 3
      MOVEMENT_TYPE_CANCELATION = 4 # liability with the account is reduced due service delivery. it can be recalculated
      MOVEMENT_TYPE_EXPIRATION = 5 # liability with the account is reduced due credits expiration. it can be recalculated
      MOVEMENT_TYPE_ADJUSTMENT = 6 # it can be recalculated
      MOVEMENT_TYPE_REFUND_ADJUSTMENT = 7 # it cannot be recalculated
    
      def after_create
        super
        # if it is payment and is not premium, update the account as premium
        if self.type == MOVEMENT_TYPE_ADD_PAYMENT && !self.account.premium 
          DB.execute("UPDATE \"account\" SET premium=TRUE WHERE id='#{self.id_account}'")
        end
      end # after_create

      def after_update
        super
        # if it is payment and is not premium, update the account as premium
        if self.type == MOVEMENT_TYPE_ADD_PAYMENT && !self.account.premium 
          DB.execute("UPDATE \"account\" SET premium=TRUE WHERE id='#{self.id_account}'")
        end
      end # after_update

      def self.types()
        [
          MOVEMENT_TYPE_ADD_PAYMENT,
          MOVEMENT_TYPE_ADD_BONUS,
          MOVEMENT_TYPE_REASSIGN_BALANCE,
          MOVEMENT_TYPE_REFUND_BALANCE,
          MOVEMENT_TYPE_CANCELATION,
          MOVEMENT_TYPE_EXPIRATION,
          MOVEMENT_TYPE_ADJUSTMENT,
          MOVEMENT_TYPE_REFUND_ADJUSTMENT
        ]
      end
    
      def self.typeName(t)
        if (t==MOVEMENT_TYPE_ADD_PAYMENT)
          return "Payment"
        elsif (t==MOVEMENT_TYPE_ADD_BONUS)
          return "Bonus"
        elsif (t==MOVEMENT_TYPE_REASSIGN_BALANCE)
          return "Reassignation"
        elsif (t==MOVEMENT_TYPE_REFUND_BALANCE)
          return "Refund"
        elsif (t==MOVEMENT_TYPE_CANCELATION)
          return "Consumption"
        elsif (t==MOVEMENT_TYPE_EXPIRATION)
          return "Expiration"
        elsif (t==MOVEMENT_TYPE_ADJUSTMENT)
          return "Credit Adjustement"
        elsif (t==MOVEMENT_TYPE_REFUND_ADJUSTMENT)
          return "Refund Adjustement"
        end
        '(unknown)'
      end

      def typeName()
        BlackStack::I2P::Movement::typeName(self.type)
      end
    
      def self.typeColorName(t)
        if (t==MOVEMENT_TYPE_ADD_PAYMENT)
          return "green"
        elsif (t==MOVEMENT_TYPE_ADD_BONUS)
          return "green"
        elsif (t==MOVEMENT_TYPE_REASSIGN_BALANCE)
          return "black"
        elsif (t==MOVEMENT_TYPE_REFUND_BALANCE)
          return "red"
        elsif (t==MOVEMENT_TYPE_CANCELATION)
          return "blue"
        elsif (t==MOVEMENT_TYPE_EXPIRATION)
          return "blue"
        elsif (t==MOVEMENT_TYPE_ADJUSTMENT)
          return "orange"
        elsif (t==MOVEMENT_TYPE_REFUND_ADJUSTMENT)
          return "orange"
        end
      end

      def typeName()
        BlackStack::I2P::Movement::typeColorName(self.type)
      end

      # actualiza el registro con los valores del item de una factura
      # type may be either MOVEMENT_TYPE_ADD_PAYMENT or MOVEMENT_TYPE_ADD_BONUS or MOVEMENT_TYPE_REFUND_BALANCE, but not other value
      def parse(item, type=MOVEMENT_TYPE_ADD_PAYMENT, description='n/a', payment_time=nil, id_item=nil)
        # the movment must be a payment or a bonus or a refund
        raise 'Movement must be either a payment or bonus or refund' if type != MOVEMENT_TYPE_ADD_PAYMENT && type != MOVEMENT_TYPE_ADD_BONUS && type != MOVEMENT_TYPE_REFUND_BALANCE
        # 
        payment_time = Time.now() if payment_time.nil?
        plan = BlackStack::I2P.plan_descriptor(item.item_number)
        prod = BlackStack::I2P.service_descriptor(plan[:service_code])
        if (self.id==nil)
          self.id=guid()
        end
        self.id_account = item.invoice.id_account
        self.id_invoice_item = id_item.nil? ? item.id : id_item
        self.create_time = item.invoice.billing_period_from #payment_time
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
        self.service_code = item.service_code
        self.profits_amount = 0
        self.description = description
        if (type == MOVEMENT_TYPE_ADD_BONUS || type == MOVEMENT_TYPE_ADD_PAYMENT)
          self.expiration_time = DB["
            SELECT TIMESTAMP '#{payment_time.to_sql}' + INTERVAL '#{prod[:credits_expiration_units].to_s} #{prod[:credits_expiration_period].to_s}' AS d
          "].first[:d].to_s
        end
        self.expiration_on_next_payment = plan[:expiration_on_next_payment]
        self.expiration_lead_period = plan[:expiration_lead_period]
        self.expiration_lead_units = plan[:expiration_lead_units]
        #self.give_away_negative_credits = plan[:give_away_negative_credits]
        self.save()
        # recalculate - CANCELADO - SE DEBE HACER OFFLINE
        #self.recalculate
        #
        self
      end

      # Returns the number of credits assigned in the movement that have been consumed.
      # The movment must be a payment or a bonus
      #
      # registraton_time: consider only movements before this time. If it is nil, this method will consider all the movements.
      # 
      def credits_consumed(registraton_time=nil)
        # le agrego 365 dias a la fecha actual, para abarcar todas las fechas ocurridas hasta hoy seguro
        if registraton_time.nil?
          registraton_time = (Time.now() + 365*24*60*60)
        else
          registraton_time = registraton_time.to_time if registraton_time.class != Time
        end
        # move time to the first second of the next day.
        # example: '2020-11-12 15:49:43 -0300' will be converted to '2020-11-13 00:00:00 -0300'
        registraton_time = (Date.strptime(registraton_time.strftime("%Y-%m-%d"), "%Y-%m-%d").to_time + 24*60*60)			
        # the movment must be a payment or a bonus
        raise 'Movement must be either a payment or a bonus' if self.type != MOVEMENT_TYPE_ADD_PAYMENT && self.type != MOVEMENT_TYPE_ADD_BONUS
        # itero los pagos y bonos hechos por este mismo producto, desde el primer dia hasta este movimiento.
        q = "
          select COALESCE(SUM(COALESCE(m.credits,0)),0) AS n 
          from movement m  
          where COALESCE(m.type, #{BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_PAYMENT.to_s}) in (#{BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_PAYMENT.to_s}, #{BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_BONUS.to_s}) 
          and m.id_account='#{self.account.id.to_guid}' 
          and COALESCE(m.credits,0) < 0 
          and UPPER(COALESCE(m.service_code, '')) = '#{self.service_code.upcase}' 
          and m.create_time < '#{registraton_time.to_time.strftime('%Y-%m-%d')}' 
          and m.create_time <= (select m2.create_time from movement m2 where m2.id='#{self.id.to_guid}') 
        "
        paid = 0 - DB[q].first[:n]
        # calculo los credito para este producto, desde el primer dia; incluyendo cosumo, expiraciones, ajustes.
        q = " 
          select COALESCE(SUM(COALESCE(m.credits,0)),0) AS n 
          from movement m 
          where m.id_account='#{self.account.id.to_guid}' 
          and COALESCE(m.credits,0) > 0 
          and UPPER(COALESCE(m.service_code, '')) = '#{self.service_code.upcase}' 
          and m.create_time < '#{registraton_time.to_time.strftime('%Y-%m-%d')}'  
        "
        consumed = DB[q].first[:n]

        # calculo los creditos de este movimiento que voy a cancelar
        credits = 0.to_f - self.credits.to_f

        # 
        if paid - consumed <= 0 # # se consumio todo
          return credits 
        else # paid - consumed > 0 # todavia no se consumio todo
          if paid - consumed > credits # todavia se estan consumiendo creditos de los pagos anteriores
            return 0
          else # paid - consumed >= credits # se consumio una parte del credito
            n = credits >= (paid - consumed) ? credits - (paid - consumed) : credits
            return n
          end
        end
      end

      # returns the real expiration based on expiration_time, expiration_lead_period and expiration_lead_units
      def expiration_lead_time()
        return nil if self.expiration_time.nil?
        return self.expiration_time if self.expiration_lead_period.nil? || self.expiration_lead_units.nil?
        if self.expiration_lead_period == 'H' # hours
          return self.expiration_time + self.expiration_lead_units.to_i * 60*60
        elsif self.expiration_lead_period == 'D' # days
          return self.expiration_time + self.expiration_lead_units.to_i * 24*60*60
        elsif self.expiration_lead_period == 'W' # weeks
          return self.expiration_time + self.expiration_lead_units.to_i * 7*24*60*60
        elsif self.expiration_lead_period == 'M' # months
          return self.expiration_time + self.expiration_lead_units.to_i * 31*24*60*60
        elsif self.expiration_lead_period == 'Y' # years
          return self.expiration_time + self.expiration_lead_units.to_i * 366*24*60*60
        else
          return self.expiration_time
        end
      end

      # credits expiration
      def expire(registraton_time=nil, desc='Expiration Because Allocation is Renewed')
        credits_consumed = self.credits_consumed(registraton_time)
        # 
        self.expiration_start_time = now()
        self.expiration_tries = self.expiration_tries.to_i + 1
        self.save
        # 
        balance = BlackStack::I2P::Balance.new(self.account.id, self.service_code, registraton_time)
        balance.calculate
        total_credits = 0.to_f - balance.credits.to_f
        total_amount = 0.to_f - balance.amount.to_f
        #
        credits = 0.to_i - self.credits.to_i
        #
        credits_to_expire = credits - credits_consumed.to_i #- (0.to_f - self.credits.to_f)).to_i
        amount_to_expire = total_credits.to_f == 0 ? 0 : credits_to_expire.to_f * ( total_amount.to_f / total_credits.to_f )
        #
        exp = BlackStack::I2P::Movement.new
        exp.id = guid()
        exp.id_account = self.account.id
        exp.create_time = registraton_time.nil? ? now() : registraton_time
        exp.type = BlackStack::I2P::Movement::MOVEMENT_TYPE_EXPIRATION
        exp.id_user_creator = self.id_user_creator
        exp.description = desc
        exp.paypal1_amount = 0
        exp.bonus_amount = 0
        exp.amount = amount_to_expire
        exp.credits = credits_to_expire
        exp.profits_amount = -amount_to_expire
        exp.id_invoice_item = self.id_invoice_item
        exp.service_code = self.service_code
        exp.save
        # 
        self.expiration_end_time = now()
        self.save
      end # def expire

      # recalculate the amount for all the consumptions.
      # The movment must be a payment or a bonus or refund
      def recalculate()
        # the movment must be a payment or a bonus or a refund
        raise 'Movement must be either a payment or bonus or refund' if type != MOVEMENT_TYPE_ADD_PAYMENT && type != MOVEMENT_TYPE_ADD_BONUS && type != MOVEMENT_TYPE_REFUND_BALANCE
        # recalculate amounts for all the consumptions and expirations
        self.account.recalculate(self.service_code)
      end 
    end # class Movement
  end # module I2P
end # module BlackStack