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
    # type may be either MOVEMENT_TYPE_ADD_PAYMENT or MOVEMENT_TYPE_ADD_BONUS, but not other value
    def parse(item, type=MOVEMENT_TYPE_ADD_PAYMENT, description='n/a', payment_time=nil, id_item=nil)
			# the movment must be a payment or a bonus
			raise 'Movement must be either a payment or a bonus' if type != MOVEMENT_TYPE_ADD_PAYMENT && type != MOVEMENT_TYPE_ADD_BONUS
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
      self.expiration_time = DB["SELECT DATEADD(#{prod[:credits_expiration_period].to_s}#{prod[:credits_expiration_period].to_s}, +#{prod[:credits_expiration_units].to_s}, '#{payment_time.to_sql}') AS d"].first[:d].to_s
			self.expiration_on_next_payment = plan[:expiration_on_next_payment]
			self.expiration_lead_period = plan[:expiration_lead_period]
			self.expiration_lead_units = plan[:expiration_lead_units]
			self.give_away_negative_credits = plan[:give_away_negative_credits]
      self.save()
			# recalculate
			self.recalculate
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

		# recalculate the amount for all the consumptions after this movement.
		# The movment must be a payment or a bonus
		def recalculate()
			# the movment must be a payment or a bonus
			raise 'Movement must be either a payment or a bonus' if self.type != MOVEMENT_TYPE_ADD_PAYMENT && self.type != MOVEMENT_TYPE_ADD_BONUS
			# 
			amount_paid = 0.to_f
			credits_paid = 0
puts
puts "recalculate:#{self.product_code}:."
			self.client.movements.select { |o| 
				#(o.type == MOVEMENT_TYPE_ADD_PAYMENT || o.type == MOVEMENT_TYPE_ADD_BONUS) &&
        #o.credits.to_f < 0 &&
				o.create_time >= self.create_time
        o.product_code.upcase == self.product_code.upcase
      }.sort_by { |o| o.create_time }.each { |o|
puts 'a'
				if o.credits.to_f < 0 # payment or bonus
puts 'b'
					amount_paid += 0.to_f - o.amount.to_f
					credits_paid += 0.to_i - o.credits.to_i
				else # consumption or adjustment
puts 'c'
					o.amount = o.credits.to_f * ( amount_paid.to_f / credits_paid.to_f )
					o.profits_amount = -o.amount
					o.save
				end
			}
		end 

  end # class Movement
end # module BlackStack