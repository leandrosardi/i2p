module BlackStack
  module I2P
    	# Inherit from BlackStack::MySaaS::Account.
    	# Add methods regarding the I2P extension.
    	class Account < BlackStack::MySaaS::Account
      		one_to_many :subscriptions, :class=>:'BlackStack::I2P::Subscription', :key=>:id_account
      		#one_to_many :customplans, :class=>:'BlackStack::I2P::CustomPlan', :key=>:id_account

	  		def hasBillingAddress?
				false
				# TODO: Code Me! 
				# https://github.com/leandrosardi/i2p/issues/2
			end
	
      		# Return an array of movements of this account.
      		# 
      		# This method replace the line:
      		# one_to_many :movements, :class=>:'BlackStack::I2P::Movement', :key=>:id_account
      		# 
      		# Because when you have a large number of records in the table movement, for a account, 
      		# then the call to this attribute account.movements can take too much time and generates
      		# a query timeout exception.
      		# 
      		# The call to this method may take too much time, but ti won't raise a query timeout.
      		# 
      		def movements
        		i = 0 
        		ret = []
        		BlackStack::I2P::Movement.where(:id_account=>self.id).each { |o| 
          			ret << o
          			i += 1
          			if i == 1000
            			i = 0
            			GC.start
            			DB.disconnect
          			end
        		}
        		ret
      		end

      		# crea/actualiza un registro en la tabla movment, reduciendo la cantidad de creditos y saldo que tiene el accounte, para el producto indicado en service_code. 
      		def consume(service_code, number_of_credits=1, description=nil, datetime=nil)
				dt = datetime.nil? ? now() : datetime.to_time.to_sql
				
				# create the consumtion
				total_credits = 0.to_f - BlackStack::I2P::Balance.new(self.id, service_code).credits.to_f
				total_amount = 0.to_f - BlackStack::I2P::Balance.new(self.id, service_code).amount.to_f
				ratio = total_credits == 0 ? 0.to_f : total_amount.to_f / total_credits.to_f
				amount = number_of_credits.to_f * ratio
				cons = BlackStack::I2P::Movement.new
				cons.id = guid()
				cons.id_account = self.id
				cons.create_time = dt
				cons.type = BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION
				cons.description = description.nil? ? 'Consumption' : description
				cons.paypal1_amount = 0
				cons.bonus_amount = 0
				cons.amount = amount
				cons.credits = number_of_credits
				cons.profits_amount = -amount
				cons.service_code = service_code
				cons.expiration_time = nil
				cons.save
				# if there is negative credits
				prod = BlackStack::I2P.product_descriptor(service_code)
				total_credits = 0.to_f - BlackStack::I2P::Balance.new(self.id, service_code).credits.to_f
				total_amount = 0.to_f - BlackStack::I2P::Balance.new(self.id, service_code).amount.to_f
				sleep(2) # delay to ensure the time of the bonus movement will be later than the time of the consumption movement
				if total_credits < 0
					self.adjustment(service_code, total_amount, total_credits, 'Adjustment Because Quota Has Been Exceeded (1).')
				end
				# recaculate amounts in both consumptions and expirations - CANCELADO - Se debe hacer offline
				#self.recalculate(service_code) 
				# return
				cons
      		end

      		# crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en service_code. 
      		def bonus(service_code, expiration, number_of_credits=1, description=nil)				
				bonus_amount = 0 # Los bonos siempre son por un importa igual a 0.
				
				bonus = BlackStack::I2P::Movement.new
				bonus.id = guid()
				bonus.id_account = self.id
				bonus.create_time = now()
				bonus.type = BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_BONUS
				bonus.description = description.nil? ? 'Bonus' : description
				bonus.paypal1_amount = 0
				bonus.bonus_amount = bonus_amount
				bonus.amount = -bonus_amount
				bonus.credits = -number_of_credits
				bonus.profits_amount = 0
				bonus.service_code = service_code
				bonus.expiration_time = expiration
				bonus.save
				# recalculate - CANCELADO
				#bonus.recalculate
				# return
				bonus
      		end

      		# crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en service_code. 
      		def adjustment(service_code, adjustment_amount=0, adjustment_credits=0, description=nil, type=BlackStack::I2P::Movement::MOVEMENT_TYPE_ADJUSTMENT, registraton_time=nil)
				adjust = BlackStack::I2P::Movement.new
				adjust.id = guid()
				adjust.id_account = self.id
				adjust.create_time = registraton_time.nil? ? now() : registraton_time
				adjust.type = type
				adjust.description = description.nil? ? 'Adjustment' : description
				adjust.paypal1_amount = 0
				adjust.bonus_amount = 0
				adjust.amount = adjustment_amount
				adjust.credits = adjustment_credits
				adjust.profits_amount = -adjustment_amount
				adjust.service_code = service_code
				adjust.expiration_time = nil
				adjust.save
				adjust
      		end

			# recalculate the amount for all the consumptions, expirations, and adjustments
			def recalculate(service_code)
				# 
				amount_paid = 0.to_f
				credits_paid = 0

				self.movements.select { |o| 
					o.service_code.upcase == service_code.upcase
				}.sort_by { |o| [o.create_time, o.type] }.each { |o| # se ordena por o.create_time, pero tmabien por o.type para procesar primero los pagos y bonos
					# consumption or expiration or bonus
					if ( 
						o.type==BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION || 
						o.type==BlackStack::I2P::Movement::MOVEMENT_TYPE_EXPIRATION || 
						o.type==BlackStack::I2P::Movement::MOVEMENT_TYPE_ADJUSTMENT
					)
						x = credits_paid.to_f == 0 ? 0 : o.credits.to_f * ( amount_paid.to_f / credits_paid.to_f )
						o.amount = x
						o.profits_amount = -x
						o.save
					end
					amount_paid += 0.to_f - o.amount.to_f
					credits_paid += 0.to_i - o.credits.to_i

					# if there is negative credits
					total_credits = credits_paid
					total_amount = amount_paid
					if total_credits < 0
						self. adjustment(service_code, total_amount, total_credits, 'Adjustment Because Quota Has Been Exceeded (2).', BlackStack::I2P::Movement::MOVEMENT_TYPE_ADJUSTMENT, o.create_time)
						amount_paid = 0.to_f
						credits_paid = 0.to_i
					end
				}
			end 
		    
      		# return true if the account is no longer allowed to take a trial
      		def disabled_trial?
        		!self.disabled_trial.nil? && self.disabled_trial == true
      		end

			# 
			def balance
				n = 0
				BlackStack::I2P::services_descriptor.each { |code| 
					n += BlackStack::I2P::Balance.new(self.id, code).amount 
				}
				n
			end

			# 
			def balance(code)
				BlackStack::I2P::Balance.new(self.id, code).amount 
			end

			# 
			def credits(code)
				BlackStack::I2P::Balance.new(self.id, code).credits 
			end

			# retorna true si existe algun item de factura relacionado al 'plan' ('item_number').
			# si el atributo 'amount' ademas es distinto a nil, se filtran items por ese monto.
			def has_item(item_number, amount=nil)
				h = BlackStack::I2P::plans_descriptor.select { |obj| obj[:item_number].to_s == item_number.to_s }.first
				raise "Plan not found" if h.nil?
					
				q = 
				"SELECT i.id " + 
				"FROM invoice i "
			
				# si el plan tiene un trial, entnces se pregunta si ya existe un item de factura por el importe del trial.
				# si el plan no tiene un trial, entnces se pregunta si ya existe un item de factura por el importe del plan.
				if amount.nil? 
				q +=
				"JOIN invoice_item t ON ( i.id=t.id_invoice AND t.item_number='#{item_number}' ) "
				else
				q +=
				"JOIN invoice_item t ON ( i.id=t.id_invoice AND t.item_number='#{item_number}' AND t.amount=#{amount.to_s} ) "
				end
				
				q +=
				"WHERE i.id_account='#{self.id}' " +
				"AND i.delete_time IS NULL "
				
				return !DB[q].first.nil?
			end
    
			# retorna los planes estandar definidos en el array BlackStack::I2P::plans_descriptor, y le concatena los arrays customizados de este accounte definidos en la tabla custom_plan
			# TODO: someday, add custom plans here
			def plans
				a = BlackStack::I2P::plans_descriptor 
=begin
				self.customplans.each { |p|
				a << p.to_hash
				}
=end
				a
			end
    	end # class Account
	end # module I2P
end # module BlackStack