module BlackStack
  module I2P
    	# Inherit from BlackStack::MySaaS::Account.
    	# Add methods regarding the I2P extension.
    	class Account < BlackStack::MySaaS::Account
      		one_to_many :subscriptions, :class=>:'BlackStack::I2P::Subscription', :key=>:id_account
      		#one_to_many :customplans, :class=>:'BlackStack::I2P::CustomPlan', :key=>:id_account
			
			# deadline is the overdue date of the last paid invoice
			def deadline
				q = "
				select max(i.billing_period_to) as account_deadline 
				from invoice i 
				where i.id_account = '#{self.id}' 
				and coalesce(i.status,0)=1
				"
				DB[q].first[:account_deadline]
			end

			# update `balance` snapshot for the given accounts.
			# update `balance` snapshot for all accounts if `aids` is nil.
			def self.update_balance_snapshot(aids=nil)
				q = "
					insert into balance (id, id_account, service_code, last_update_time, credits, amount)
					select gen_random_uuid(), m.id_account, m.service_code, current_timestamp(), cast(sum(m.credits) as int8) as credits_update, sum(m.amount) as amount_update
					from movement m
					#{aids.nil? ? '' : "where m.id_account in ('#{aids.join("','")}')" }
					group by m.id_account, m.service_code 
					on conflict (id_Account, service_code)
					do update set last_update_time=current_timestamp(), credits=excluded.credits, amount=excluded.amount;
				"
				DB.execute(q)
			end

			# update `balance` snapshot for all accounts
			def self.update_balance_snapshot_all
				BlackStack::I2P::Account.update_balance_snapshot(nil)
			end

			# update `balance` snapshot for this account
			def update_balance_snapshot
				BlackStack::I2P::Account.update_balance_snapshot([self.id])
			end

			# return true if this account is premium
			# return false otherwise
			def premium?
				self.premium
			end

	  		def hasBillingAddress?
				!billing_address.nil? && !billing_city.nil? && !billing_state.nil? && !billing_zipcode.nil? && !billing_country.nil?
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

			# update the snapshot `balance`
			# reference: https://github.com/leandrosardi/i2p/issues/22
			def self.update_balance()
				q = "
				insert into balance (id, id_account, service_code, last_update_time, credits, amount)
				select gen_random_uuid(), m.id_account, m.service_code, current_timestamp(), sum(m.credits) as credits_update, sum(m.amount) as amount_update
				from movement m
				group by m.id_account, m.service_code 
				on conflict (id_Account, service_code)
				do update set last_update_time=current_timestamp(), credits=excluded.credits, amount=excluded.amount
				"
				DB.execute(q)
			end

			# update the snapshot `balance`
			# reference: https://github.com/leandrosardi/i2p/issues/22
			def update_balance()
				q = "
				insert into balance (id, id_account, service_code, last_update_time, credits, amount)
				select gen_random_uuid(), m.id_account, m.service_code, current_timestamp(), cast(sum(m.credits) as int) as credits_update, sum(m.amount) as amount_update
				from movement m
				where m.id_account='#{self.id}'
				group by m.id_account, m.service_code 
				on conflict (id_Account, service_code)
				do update set last_update_time=current_timestamp(), credits=excluded.credits, amount=excluded.amount
				"
				DB.execute(q)
			end

			# update the table `movement`, with the credits consumed today
			def update_consumption_of_the_day(service_code, rightnow=nil, l=nil)
                rightnow = now if rightnow.nil?
                today = Time.new(rightnow.year, rightnow.month, rightnow.day, 0, 0, 0)
				h = BlackStack::I2P::services_descriptor.select { |i| service_code == i[:code] }.first
				n = h[:consumed_function].call(self.id, today)

				# get payments/credit rate, from the while history of movements of this account
				self.update_balance
				balance = BlackStack::I2P::Balance.new(self.id, service_code)
				total_credits = 0.to_f - balance.credits.to_f
				total_amount = 0.to_f - balance.amount.to_f
				ratio = total_credits == 0 ? 0.to_f : total_amount.to_f / total_credits.to_f
				amount = n.to_f * ratio

				# validate atomicity
				#raise "Atomicity error: credits0=#{credits0}, total_credits=#{total_credits}" if credits0 != total_credits

				# update credits
				# load the movments for this id_account, dt, type, service_code
				q = "
					SELECT m.id
					FROM movement m
					WHERE m.id_account = '#{self.id}'
					AND m.service_code = '#{service_code}'
					AND m.type = #{BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION}
					AND date_part('year', m.create_time) = '#{today.year}'
					AND date_part('month', m.create_time) = '#{today.month}'
					AND date_part('day', m.create_time) = '#{today.day}'
				"
				row = DB[q].first
				# if there is a movement for this id_account, dt, service_code, then update it
				if row.nil?
					# create a new movement
					m = BlackStack::I2P::Movement.new
					m.id = guid
					m.create_time = today
					m.id_account = self.id
					m.service_code = service_code
					m.type = BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION
					m.description = "Cancelation for #{service_code} on #{today}"
					m.paypal1_amount = 0
					m.bonus_amount = 0
				else
					m = BlackStack::I2P::Movement.where(:id=>row[:id]).first
				end
				m.amount = amount
				m.profits_amount = -amount
				m.credits = n
				m.save				
			end

			# update the table `movement`
			# reference: https://github.com/leandrosardi/i2p/issues/24
			def update_movements(l=nil)
                l = BlackStack::DummyLogger.new(nil) if l.nil?
                # Get latetest date-hour in the `eml_timeline` for this address, and store it in the variable `last`.
                # If there is no `eml_timeline` for this address, set `2023-01-01` as default value.
                l.logs 'Get the latest date-hour... '
                last = self.movement_last_date_processed
                last = self.create_time if last.nil?
                last = Time.new(2023,1,1) if last.nil?
                l.logf "done (#{last})"
                # Iterate all date-hours from `last` to now, using the table `daily` joined with `hourly`.
                # Each iteration store such a date-hour in the variable `dt`.
                l.logs 'Iterate all date-hours from `last` to now...'
                rightnow = now
                lastday = Time.new(last.year, last.month, last.day, 0, 0)
                today = Time.new(rightnow.year, rightnow.month, rightnow.day, 0, 0, 0)
				# move `lastday` 1 day before, in case that new activity happned in the last secod of the previ
                
				# iterate days
				BlackStack::MySaaS::Daily.where(:date=>lastday.to_time..today).order(:date).all do |daily|
                    l.logs "#{daily.date}... "
                    # update `movement_last_date_processed` for this account
					query_update = "UPDATE account SET movement_last_date_processed='#{daily.date}' WHERE id='#{self.id}'"
					DB.execute(query_update)
					# iterate the services
					BlackStack::I2P::services_descriptor.each { |h|
						service_code = h[:code]
						l.logs "Service #{service_code}... "
						if h[:consumed_function].nil?
							l.logf "skipped"
						else
							# get total credits of this account and service
							# note: such a value must be the same after get the number of consumption, 
							# in order to calculate the credit rate with no incongruences (atomicity).
							self.update_balance
							credits0 = 0.to_f - BlackStack::I2P::Balance.new(self.id, service_code).credits.to_f
							# load the consumption for this id_account, dt, type, service_code
							l.logs "Loading consumption... "
							n = h[:consumed_function].call(self.id, daily.date)				
							l.logf "done (#{n})"
							if n > 0
								# get credit rate
								self.update_balance
								balance = BlackStack::I2P::Balance.new(self.id, service_code)
								total_credits = 0.to_f - balance.credits.to_f
								total_amount = 0.to_f - balance.amount.to_f
								ratio = total_credits == 0 ? 0.to_f : total_amount.to_f / total_credits.to_f
								amount = n.to_f * ratio
								# validate atomicity
								raise "Atomicity error: credits0=#{credits0}, total_credits=#{total_credits}" if credits0 != total_credits
								# load the movments for this id_account, dt, type, service_code
								q = "
									SELECT m.id
									FROM movement m
									WHERE m.id_account = '#{self.id}'
									AND m.service_code = '#{h[:code]}'
									AND m.type = #{BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION}
									AND date_part('year', m.create_time) = '#{daily.date.year}'
									AND date_part('month', m.create_time) = '#{daily.date.month}'
									AND date_part('day', m.create_time) = '#{daily.date.day}'
								"
								row = DB[q].first
								# if there is a movement for this id_account, dt, service_code, then update it
								if row.nil?
									# create a new movement
									m = BlackStack::I2P::Movement.new
									m.id = guid
									m.create_time = daily.date
									m.id_account = self.id
									m.service_code = h[:code]
									m.type = BlackStack::I2P::Movement::MOVEMENT_TYPE_CANCELATION
									m.description = "Cancelation for #{h[:code]} on #{daily.date}"
									m.paypal1_amount = 0
									m.bonus_amount = 0
								else
									m = BlackStack::I2P::Movement.where(:id=>row[:id]).first
								end
								m.amount = amount
								m.profits_amount = -amount
								m.credits = n
								m.save
							end
							# 
							l.done
						end
					}
					l.done
                end # each daily
                l.done
            end # def update_timeline

			# TODO: deprecated
      		# crea/actualiza un registro en la tabla movment, reduciendo la cantidad de creditos y saldo que tiene el accounte, para el producto indicado en service_code. 
      		def consume(service_code, number_of_credits=1, description=nil, datetime=nil)
				dt = datetime.nil? ? now() : datetime.to_time.to_sql
				
				# create the consumtion
				balance = BlackStack::I2P::Balance.new(self.id, service_code)
				total_credits = 0.to_f - balance.credits.to_f
				total_amount = 0.to_f - balance.amount.to_f
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
# TODO: deprecated
=begin 
				# if there is negative credits
				prod = BlackStack::I2P.service_descriptor(service_code)
				balance = BlackStack::I2P::Balance.new(self.id, service_code)
				total_credits = 0.to_f - balance.credits.to_f
				total_amount = 0.to_f - balance.amount.to_f
				#sleep(2) # delay to ensure the time of the bonus movement will be later than the time of the consumption movement
				if total_credits < 0
					self.adjustment(service_code, total_amount, total_credits, 'Adjustment Because Quota Has Been Exceeded (1).')
				end
				
				# recaculate amounts in both consumptions and expirations - CANCELADO - Se debe hacer offline
				#self.recalculate(service_code) 
=end				
				# return
				cons
      		end

      		# crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en service_code. 
      		def bonus(service_code, expiration, bonus_amount, number_of_credits=1, description=nil)				
				raise 'bonus_amount must be higher than 0' if bonus_amount.to_f < 0.to_f
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
				-n
			end

			# 
			def balance(code)
				-BlackStack::I2P::Balance.new(self.id, code).amount 
			end

			# 
			def credits(code)
				-BlackStack::I2P::Balance.new(self.id, code).credits 
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