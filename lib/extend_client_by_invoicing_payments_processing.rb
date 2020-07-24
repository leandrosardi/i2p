module BlackStack
  
    # 
    # 
    # 
    class Client < Sequel::Model(:client)
      one_to_many :paypal_subscriptions, :class=>:'BlackStack::PayPalSubscription', :key=>:id_client
      one_to_many :customplans, :class=>:'BlackStack::CustomPlan', :key=>:id_client
      one_to_many :movements, :class=>:'BlackStack::Movement', :key=>:id_client

      # crea/actualiza un registro en la tabla movment, reduciendo la cantidad de creditos y saldo que tiene el cliente, para el producto indicado en product_code. 
      def consume(product_code, number_of_credits=1, description=nil)
        DB.execute("exec reduceDebt '#{product_code.to_sql}', '#{self.id}', #{number_of_credits.to_s}, '#{description.to_s.to_sql}'")
				# if there is negative credits and
				# give_away_negative_credits is ON
				prod = BlackStack::InvoicingPaymentsProcessing.product_descriptor(product_code)
				total_credits = 0.to_f - BlackStack::Balance.new(self.id, product_code).credits.to_f
				total_amount = 0.to_f - BlackStack::Balance.new(self.id, product_code).amount.to_f
#puts
#puts "total_credits:#{total_credits.to_s}:."
#puts "give_away_negative_credits:#{prod[:give_away_negative_credits].to_s}:."

				# delay to ensure the time of the bonus movement will be later than the time of the consumption movement
				sleep(2)
				if total_credits < 0 && prod[:give_away_negative_credits] == true
					self.bonus(product_code, nil, -total_credits, -total_amount, 'Bonus Because Quota Has Been Exceeded.')
				end
				
				# recaculate amounts in both consumptions and expirations
				self.recalculate(product_code)
      end

      # crea un registro en la tabla movment, reduciendo la cantidad de creditos con saldo importe 0, para el producto indicado en product_code. 
      def bonus(product_code, expiration, number_of_credits=1, bonus_amount=0, description=nil)
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
				# recalculate
				bonus.recalculate
      end

			# recalculate the amount for all the consumptions.
			# The movment must be a payment or a bonus
			def recalculate(product_code)
				# 
				amount_paid = 0.to_f
				credits_paid = 0

				self.movements.select { |o| 
					o.product_code.upcase == product_code.upcase
				}.sort_by { |o| o.create_time }.each { |o|
					#if o.credits.to_f < 0 # payment or bonus
					if o.credits.to_f > 0 # consumption or expiration
						o.amount = o.credits.to_f * ( amount_paid.to_f / credits_paid.to_f )
						o.profits_amount = -o.amount
						o.save
					end
					amount_paid += 0.to_f - o.amount.to_f
					credits_paid += 0.to_i - o.credits.to_i
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
        if to_time.prev_year > from_time
          raise "There time frame cannot be longer than 1 year."
        end
        to_time += 1
        ds = BlackStack::Movement.where(:id_client => self.id, :product_code=>product_code) if !product_code.nil?
        ds = BlackStack::Movement.where(:id_client => self.id) if product_code.nil?
        ds.where("create_time >= ? and create_time <= ?", from_time, to_time)
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