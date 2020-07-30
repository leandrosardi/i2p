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
		MOVEMENT_TYPE_ADJUSTMENT = 6 
  
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
    # type may be either MOVEMENT_TYPE_ADD_PAYMENT or MOVEMENT_TYPE_ADD_BONUS or MOVEMENT_TYPE_REFUND_BALANCE, but not other value
    def parse(item, type=MOVEMENT_TYPE_ADD_PAYMENT, description='n/a', payment_time=nil, id_item=nil)
			# the movment must be a payment or a bonus or a refund
			raise 'Movement must be either a payment or bonus or refund' if type != MOVEMENT_TYPE_ADD_PAYMENT && type != MOVEMENT_TYPE_ADD_BONUS && type != MOVEMENT_TYPE_REFUND_BALANCE
			# 
      payment_time = Time.now() if payment_time.nil?
			plan = BlackStack::InvoicingPaymentsProcessing.plan_descriptor(item.item_number)
      prod = BlackStack::InvoicingPaymentsProcessing.product_descriptor(plan[:product_code])
      if (self.id==nil)
        self.id=guid()
      end
      self.id_client = item.invoice.id_client
      self.id_invoice_item = id_item.nil? ? item.id : id_item
      self.create_time = payment_time #item.invoice.billing_period_from
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
      if (type == MOVEMENT_TYPE_ADD_BONUS || type == MOVEMENT_TYPE_ADD_PAYMENT)
				self.expiration_time = DB["SELECT DATEADD(#{prod[:credits_expiration_period].to_s}#{prod[:credits_expiration_period].to_s}, +#{prod[:credits_expiration_units].to_s}, '#{payment_time.to_sql}') AS d"].first[:d].to_s
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
		def credits_consumed()
			# the movment must be a payment or a bonus
			raise 'Movement must be either a payment or a bonus' if self.type != MOVEMENT_TYPE_ADD_PAYMENT && self.type != MOVEMENT_TYPE_ADD_BONUS
#puts
#puts "product_code:#{self.product_code}:."
			# itero los pagos y bonos hechos por este mismo producto, desde el primer dia hasta este movimiento.
			paid = 0
			self.client.movements.select { |o| 
				(o.type == MOVEMENT_TYPE_ADD_PAYMENT || o.type == MOVEMENT_TYPE_ADD_BONUS) &&
        o.credits.to_f < 0 &&
        o.product_code.upcase == self.product_code.upcase
      }.sort_by { |o| o.create_time }.each { |o|
				paid += (0.to_f - o.credits.to_f)
				break if o.id.to_guid == self.id.to_guid
			}
#puts "paid:#{paid.to_s}:."
      # calculo los credito para este producto, desde el primer dia; incluyendo cosumo, expiraciones, ajustes.
      consumed = self.client.movements.select { |o| 
        o.credits.to_f > 0 &&
        o.product_code.upcase == self.product_code.upcase
      }.inject(0) { |sum, o| sum.to_f + o.credits.to_f }.to_f
#puts "consumed:#{consumed.to_s}:."			
      # calculo los creditos de este movimiento que voy a cancelar
      credits = 0.to_f - self.credits.to_f
#puts "credits:#{credits.to_s}:."
			# 
			if paid - consumed <= 0 # # se consumio todo
#puts "a"
				return credits 
			else # paid - consumed > 0 # todavia no se consumio todo
				if paid - consumed > credits # todavia se estan consumiendo creditos de los pagos anteriores
#puts "b"
					return 0
				else # paid - consumed >= credits # se consumio una parte del credito
#puts "c"
					n = credits >= (paid - consumed) ? credits - (paid - consumed) : credits
#puts "n:#{n.to_s}:."
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
		def expire()
			credits_consumed = self.credits_consumed
			# 
			self.expiration_start_time = now()
			self.expiration_tries = self.expiration_tries.to_i + 1
			self.save
			# 
			total_credits = 0.to_f - BlackStack::Balance.new(self.client.id, self.product_code).credits.to_f
			total_amount = 0.to_f - BlackStack::Balance.new(self.client.id, self.product_code).amount.to_f
			#
			credits = 0.to_i - self.credits.to_i
			#
			credits_to_expire = credits - credits_consumed.to_i #- (0.to_f - self.credits.to_f)).to_i
			amount_to_expire = credits_to_expire.to_f * ( total_amount.to_f / total_credits.to_f )
			#
			exp = BlackStack::Movement.new
			exp.id = guid()
			exp.id_client = self.client.id
			exp.create_time = now()
			exp.type = BlackStack::Movement::MOVEMENT_TYPE_EXPIRATION
			exp.id_user_creator = self.id_user_creator
			exp.description = 'Expiration Because Allocation is Renewed'
			exp.paypal1_amount = 0
			exp.bonus_amount = 0
			exp.amount = amount_to_expire
			exp.credits = credits_to_expire
			exp.profits_amount = -amount_to_expire
			exp.id_invoice_item = self.id_invoice_item
			exp.product_code = self.product_code
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
			self.client.recalculate(self.product_code)
		end 

  end # class Movement
end # module BlackStack