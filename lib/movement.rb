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
    MOVEMENT_TYPE_CANCELATION = 4 # liability with the client is reduced due service delivery. it can be recalculated
    MOVEMENT_TYPE_EXPIRATION = 5 # liability with the client is reduced due credits expiration. it can be recalculated
		MOVEMENT_TYPE_ADJUSTMENT = 6 # it can be recalculated
		MOVEMENT_TYPE_REFUND_ADJUSTMENT = 7 # it cannot be recalculated
  
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
      BlackStack::Movement::typeName(self.type)
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
      BlackStack::Movement::typeColorName(self.type)
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
#puts
#puts "id:#{self.id.to_guid}:."
#puts "product_code:#{self.product_code}:."
			# itero los pagos y bonos hechos por este mismo producto, desde el primer dia hasta este movimiento.
=begin
			paid1 = 0
			self.client.movements.select { |o| 
				(o.type == MOVEMENT_TYPE_ADD_PAYMENT || o.type == MOVEMENT_TYPE_ADD_BONUS) &&
        o.credits.to_f < 0 &&
        o.product_code.upcase == self.product_code.upcase &&
        o.create_time.to_time < registraton_time.to_time
      }.sort_by { |o| o.create_time }.each { |o|
				paid1 += (0.to_f - o.credits.to_f)
				break if o.id.to_guid == self.id.to_guid
			}
#puts "paid1:#{paid1.to_s}:."
=end
      q = 
        "select ISNULL(SUM(ISNULL(m.credits,0)),0) AS n " +
        "from movement m with (nolock index(IX_movement__type__id_client__product_code__create_time_desc__credits_desc)) " +
        "where isnull(m.type, #{BlackStack::Movement::MOVEMENT_TYPE_ADD_PAYMENT.to_s}) in (#{BlackStack::Movement::MOVEMENT_TYPE_ADD_PAYMENT.to_s}, #{BlackStack::Movement::MOVEMENT_TYPE_ADD_BONUS.to_s}) " +
        "and m.id_client='#{self.client.id.to_guid}' " +
        "and isnull(m.credits,0) < 0 " +
        "and upper(isnull(m.product_code, '')) = '#{self.product_code.upcase}' " +
        "and m.create_time < '#{registraton_time.to_time.strftime('%Y-%m-%d')}' " +
        "and m.create_time <= (select m2.create_time from movement m2 with (nolock) where m2.id='#{self.id.to_guid}') "
      paid = 0 - DB[q].first[:n]
#puts "q:#{q.to_s}:."
#puts "paid:#{paid.to_s}:."
=begin
      # calculo los credito para este producto, desde el primer dia; incluyendo cosumo, expiraciones, ajustes.
      consumed1 = self.client.movements.select { |o| 
        o.credits.to_f > 0 &&
        o.product_code.upcase == self.product_code.upcase &&
        o.create_time.to_time < registraton_time.to_time
      }.inject(0) { |sum, o| sum.to_f + o.credits.to_f }.to_f
#puts "consumed1:#{consumed1.to_s}:."     
=end
      q = 
        "select ISNULL(SUM(ISNULL(m.credits,0)),0) AS n " +
        "from movement m with (nolock index(IX_movement__type__id_client__product_code__create_time_desc__credits_asc)) " +
        "where m.id_client='#{self.client.id.to_guid}' " +
        "and isnull(m.credits,0) > 0 " +
        "and upper(isnull(m.product_code, '')) = '#{self.product_code.upcase}' " +
        "and m.create_time < '#{registraton_time.to_time.strftime('%Y-%m-%d')}' " #+
#        "and m.id <> '#{self.id.to_guid}' "
      consumed = DB[q].first[:n]
#puts "q:#{q.to_s}:."
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
		def expire(registraton_time=nil, desc='Expiration Because Allocation is Renewed')
#puts
#puts "registraton_time:#{registraton_time.to_s}:."
			credits_consumed = self.credits_consumed(registraton_time)
#puts "credits_consumed:#{credits_consumed.to_s}:."
			# 
			self.expiration_start_time = now()
			self.expiration_tries = self.expiration_tries.to_i + 1
			self.save
			# 
			balance = BlackStack::Balance.new(self.client.id, self.product_code, registraton_time)
			balance.calculate(false)
#puts "balance.credits.to_s:#{balance.credits.to_s}:."
#puts "balance.amount.to_s:#{balance.amount.to_s}:."
			total_credits = 0.to_f - balance.credits.to_f
			total_amount = 0.to_f - balance.amount.to_f
			#
			credits = 0.to_i - self.credits.to_i
			#
			credits_to_expire = credits - credits_consumed.to_i #- (0.to_f - self.credits.to_f)).to_i
			amount_to_expire = total_credits.to_f == 0 ? 0 : credits_to_expire.to_f * ( total_amount.to_f / total_credits.to_f )
#puts "credits_to_expire.to_s:#{credits_to_expire.to_s}:."
#puts "amount_to_expire.to_s:#{amount_to_expire.to_s}:."
			#
			exp = BlackStack::Movement.new
			exp.id = guid()
			exp.id_client = self.client.id
			exp.create_time = registraton_time.nil? ? now() : registraton_time
			exp.type = BlackStack::Movement::MOVEMENT_TYPE_EXPIRATION
			exp.id_user_creator = self.id_user_creator
			exp.description = desc
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