module BlackStack
  
    # 
    # 
    # 
    class Client < Sequel::Model(:client)
      one_to_many :paypal_subscriptions, :class=>:'BlackStack::PayPalSubscription', :key=>:id_client
      one_to_many :customplans, :class=>:'BlackStack::CustomPlan', :key=>:id_client

      # This method replace the line:
      # one_to_many :movements, :class=>:'BlackStack::Movement', :key=>:id_client
      # 
      # Because when you have a large number of records in the table movement, for a client, 
      # then the call to this attribute client.movements can take too much time and generates
      # a query timeout exception.
      # 
      # The call to this method may take too much time, but ti won't raise a query timeout.
      # 
      def movements
        i = 0 
        ret = []
        BlackStack::Movement.where(:id_client=>self.id).each { |o| 
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

      # how many minutes ago should have updated the table stat_balance with the amount and credits of this client, for each product.
      # return a positive integer if either:
      # 1. the client didn't update stats in the last 24 hours, or
      # 2. the client has a new record in the table movements after its last update in the table stat_balance.
      def stat_balance_delay_minutes
        row = DB[
          "SELECT TOP 1 m.id " +
          "FROM client c WITH (NOLOCK) " +
          "JOIN movement m WITH (NOLOCK INDEX(IX_movement__id_client__create_time_desc)) ON ( " +
          " c.id=m.id_client AND " +
          " m.create_time > ISNULL(c.last_stat_balance_update_time, '1900-01-01') " +
          ") " +
          "WHERE c.id = '#{self.id}' " +
          "ORDER BY m.create_time DESC "
        ].first
        
        if row.nil?
          return 0
        else
          return DB["SELECT DATEDIFF(MI, m.create_time, GETDATE()) AS n FROM movement m WITH (NOLOCK) WHERE m.id='#{row[:id]}'"].first[:n]
        end
      end
  
      # update the table stat_balance with the amount and credits of this client, for each product.
      def update_stat_balance(product_code=nil)
          c = self
          product_descriptors = BlackStack::InvoicingPaymentsProcessing::products_descriptor.clone     
          product_descriptors.select! { |hprod| hprod[:code] == product_code } if !product_code.nil?
          product_descriptors.each { |hprod|
            row = DB[
              "select isnull(sum(isnull(m.credits,0)),0) as credits, isnull(sum(isnull(m.amount,0)),0) as amount " +
              "from movement m with (nolock index(IX_movement__id_client__product_code)) " + 
              #"from movement m with (nolock) " + 
              "where m.id_client='#{c.id}' " +
              "and m.product_code='#{hprod[:code]}' "
            ].first
            credits = row[:credits]
            amount = row[:amount]
            row = DB["SELECT * FROM stat_balance WHERE id_client='#{c.id}' AND product_code='#{hprod[:code]}'"].first
            if row.nil?
              DB.execute("INSERT INTO stat_balance (id_client, product_code, amount, credits) VALUES ('#{c.id}', '#{hprod[:code]}', #{amount.to_s}, #{credits.to_s})")
            else
              DB.execute("UPDATE stat_balance SET amount=#{amount.to_s}, credits=#{credits.to_s} WHERE id_client='#{c.id}' AND product_code='#{hprod[:code]}'")
            end
            DB.execute("UPDATE client SET last_stat_balance_update_time=GETDATE() WHERE [id]='#{c.id}'")
          }
      end

      # crea/actualiza un registro en la tabla movment, reduciendo la cantidad de creditos y saldo que tiene el cliente, para el producto indicado en product_code. 
      def consume(product_code, number_of_credits=1, description=nil, datetime=nil)
				dt = datetime.nil? ? now() : datetime.to_time.to_sql
				
				# create the consumtion
				total_credits = 0.to_f - BlackStack::Balance.new(self.id, product_code).credits.to_f
				total_amount = 0.to_f - BlackStack::Balance.new(self.id, product_code).amount.to_f
				ratio = total_credits == 0 ? 0.to_f : total_amount.to_f / total_credits.to_f
				amount = number_of_credits.to_f * ratio
				cons = BlackStack::Movement.new
				cons.id = guid()
				cons.id_client = self.id
				cons.create_time = dt
				cons.type = BlackStack::Movement::MOVEMENT_TYPE_CANCELATION
				cons.description = description.nil? ? 'Consumption' : description
				cons.paypal1_amount = 0
				cons.bonus_amount = 0
				cons.amount = amount
				cons.credits = number_of_credits
				cons.profits_amount = -amount
				cons.product_code = product_code
				cons.expiration_time = nil
				cons.save
				# if there is negative credits
				prod = BlackStack::InvoicingPaymentsProcessing.product_descriptor(product_code)
				total_credits = 0.to_f - BlackStack::Balance.new(self.id, product_code).credits.to_f
				total_amount = 0.to_f - BlackStack::Balance.new(self.id, product_code).amount.to_f
				sleep(2) # delay to ensure the time of the bonus movement will be later than the time of the consumption movement
				if total_credits < 0
					self.adjustment(product_code, total_amount, total_credits, 'Adjustment Because Quota Has Been Exceeded (1).')
				end
				# recaculate amounts in both consumptions and expirations - CANCELADO - Se debe hacer offline
				#self.recalculate(product_code) 
				# return
				cons
      end

      # crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en product_code. 
      def bonus(product_code, expiration, number_of_credits=1, description=nil)				
				bonus_amount = 0 # Los bonos siempre son por un importa igual a 0.
				
				bonus = BlackStack::Movement.new
				bonus.id = guid()
				bonus.id_client = self.id
				bonus.create_time = now()
				bonus.type = BlackStack::Movement::MOVEMENT_TYPE_ADD_BONUS
				bonus.description = description.nil? ? 'Bonus' : description
				bonus.paypal1_amount = 0
				bonus.bonus_amount = bonus_amount
				bonus.amount = -bonus_amount
				bonus.credits = -number_of_credits
				bonus.profits_amount = 0
				bonus.product_code = product_code
				bonus.expiration_time = expiration
				bonus.save
				# recalculate - CANCELADO
				#bonus.recalculate
				# return
				bonus
      end

      # crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en product_code. 
      def adjustment(product_code, adjustment_amount=0, adjustment_credits=0, description=nil, type=BlackStack::Movement::MOVEMENT_TYPE_ADJUSTMENT, registraton_time=nil)
				adjust = BlackStack::Movement.new
				adjust.id = guid()
				adjust.id_client = self.id
				adjust.create_time = registraton_time.nil? ? now() : registraton_time
				adjust.type = type
				adjust.description = description.nil? ? 'Adjustment' : description
				adjust.paypal1_amount = 0
				adjust.bonus_amount = 0
				adjust.amount = adjustment_amount
				adjust.credits = adjustment_credits
				adjust.profits_amount = -adjustment_amount
				adjust.product_code = product_code
				adjust.expiration_time = nil
				adjust.save
				adjust
      end

			# recalculate the amount for all the consumptions, expirations, and adjustments
			def recalculate(product_code)
				# 
				amount_paid = 0.to_f
				credits_paid = 0

				#total_credits = 0.to_f - BlackStack::Balance.new(self.id, product_code).credits.to_f
				#total_amount = 0.to_f - BlackStack::Balance.new(self.id, product_code).amount.to_f        

				self.movements.select { |o| 
					o.product_code.upcase == product_code.upcase
				}.sort_by { |o| [o.create_time, o.type] }.each { |o| # se ordena por o.create_time, pero tmabien por o.type para procesar primero los pagos y bonos
					#if o.credits.to_f < 0 # payment or bonus
#					if o.credits.to_f > 0 && ( o.type==BlackStack::Movement::MOVEMENT_TYPE_CANCELATION || o.type==BlackStack::Movement::MOVEMENT_TYPE_EXPIRATION ) # consumption or expiration
					# consumption or expiration or bonus
					if ( 
						o.type==BlackStack::Movement::MOVEMENT_TYPE_CANCELATION || 
						o.type==BlackStack::Movement::MOVEMENT_TYPE_EXPIRATION || 
						o.type==BlackStack::Movement::MOVEMENT_TYPE_ADJUSTMENT
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
						self. adjustment(product_code, total_amount, total_credits, 'Adjustment Because Quota Has Been Exceeded (2).', BlackStack::Movement::MOVEMENT_TYPE_ADJUSTMENT, o.create_time)
						amount_paid = 0.to_f
						credits_paid = 0.to_i
					end
				}
			end 
		
      # TODO: el cliente deberia tener una FK a la tabla division. La relacion no puede ser N-N.
      # TODO: se debe preguntar a la central
      def division
        q = 
        "SELECT d.id as id " +
        "FROM division d " +
        "JOIN user_division ud ON d.id=ud.id_division " +
        "JOIN [user] u ON u.id=ud.id_user " +
        "WHERE u.id_client = '#{self.id}' "
        row = DB[q].first
        BlackStack::Division.where(:id=>row[:id]).first    
      end
    
      # retorna true si este cliente no tiene ninguna generada con productos LGB2
      def deserve_trial()
        self.disabled_for_trial_ssm != true
      end
    
      # 
      def deserve_trial?
        self.deserve_trial()
      end

      # 
      def get_balance()
        n = 0
        BlackStack::InvoicingPaymentsProcessing::products_descriptor.each { |code| 
          n += BlackStack::Balance.new(self.id, code).amount 
        }
        n
      end

      # 
      def get_movements(from_time, to_time, product_code=nil)
        if from_time > to_time
          raise "From time must be earlier than To time"
        end
        #if to_time.prev_year > from_time
        #  raise "The time frame cannot be longer than 1 year."
        #end
        to_time += 1
=begin
      :id => movement.id,
      :id_client => movement.id_client,
      :product_code => movement.product_code,
      :create_time => movement.create_time,
      :type => movement.type.to_i,
      :description => movement.description,
      :paypal1_amount => movement.paypal1_amount.to_f,
      :bonus_amount => movement.bonus_amount.to_f,
      :amount => movement.amount.to_f,
      :credits => movement.credits.to_f,
      :profits_amount => movement.profits_amount.to_f,
      :expiration_time => movement.expiration_time,
      :expiration_description => movement.expiration_time.nil? ? '-' : ((movement.expiration_time - Time.now()).to_f / 60.to_f).to_i.to_time_spent 
=end  
        q =
        "SELECT " +
        " m.id_client, " +
        " YEAR(m.create_time) AS creation_year, " + 
        " MONTH(m.create_time) AS creation_month, " + 
        " DAY(m.create_time) AS creation_day, " +
        " YEAR(m.expiration_time) AS expiration_year, " + 
        " MONTH(m.expiration_time) AS expiration_month, " + 
        " DAY(m.expiration_time) AS expiration_day, " +
        " m.type, " +
        " m.product_code, " +
        " CAST(m.description AS VARCHAR(500)) AS description, " +
        " CAST(m.expiration_description AS VARCHAR(500)) AS expiration_description, " +
        " SUM(ISNULL(m.paypal1_amount,0)) AS paypal1_amount, " + 
        " SUM(ISNULL(m.bonus_amount,0)) AS bonus_amount, " + 
        " SUM(ISNULL(m.amount,0)) AS amount, " + 
        " SUM(ISNULL(m.credits,0)) AS credits, " + 
        " SUM(ISNULL(m.profits_amount,0)) AS profits_amount " + 
        "FROM movement m WITH (NOLOCK) " +
        "WHERE m.id_client = '#{self.id}' "
        
        q += "AND m.product_code = '#{product_code}' " if !product_code.nil?
        
        q +=
        "AND create_time >= '#{from_time.to_sql}' " +
        "AND create_time <= '#{to_time.to_sql}' " +
        "GROUP BY " +
        " m.id_client, " + 
        " YEAR(m.create_time), " + 
        " MONTH(m.create_time), " + 
        " DAY(m.create_time), " +
        " YEAR(m.expiration_time), " + 
        " MONTH(m.expiration_time), " + 
        " DAY(m.expiration_time), " +
        " m.type, " +
        " m.product_code, " +
        " CAST(m.description AS VARCHAR(500)), " +
        " CAST(m.expiration_description AS VARCHAR(500)) "

        DB[q].all
      end

      # 
      def add_bonus(id_user_creator, product_code, bonus_credits, description, expiration_time)
        bonus_amount = 0
    #    balance = BlackStack::Balance.new(self.id, product_code)
    #    amount = balance.amount.to_f
    #    credits = balance.credits.to_f
    #    if amount>=0 && credits>=0
    #      bonus_amount = (amount / credits) * bonus_credits
    ##    else
    ##      h = BlackStack::InvoicingPaymentsProcessing.product_descriptor(product_code)
    ##      bonus_amount = h[:default_fee_per_unit].to_f
    #    end
        m = BlackStack::Movement.new(
          :id_client => self.id,
          :create_time => now(),
          :type => BlackStack::Movement::MOVEMENT_TYPE_ADD_BONUS,
          :id_user_creator => id_user_creator,
          :description => description,
          :paypal1_amount => 0,
          :bonus_amount => bonus_amount,
          :amount => 0-bonus_amount,
          :credits => 0-bonus_credits,
          :profits_amount => 0,
          :product_code => product_code,
          :expiration_time => expiration_time
        )
        m.id = guid()
        m.save
      end

      # retorna true si existe algun item de factura relacionado al 'plan' ('item_number').
      # si el atributo 'amount' ademas es distinto a nil, se filtran items por ese monto.
      def has_item(item_number, amount=nil)
        h = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |obj| obj[:item_number].to_s == item_number.to_s }.first
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
        "WHERE i.id_client='#{self.id}' "
        
        return !DB[q].first.nil?
      end
    
      # retorna los planes estandar definidos en el array BlackStack::InvoicingPaymentsProcessing::plans_descriptor, y le concatena los arrays customizados de este cliente definidos en la tabla custom_plan
      def plans
        a = BlackStack::InvoicingPaymentsProcessing::plans_descriptor 
        self.customplans.each { |p|
          a << p.to_hash
        }
        a
      end
    end # class Client

end # module BlackStack