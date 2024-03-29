module BlackStack
  module I2P

    # load all the skeletons
    def self.server_side
        require 'extensions/i2p/lib/skeletons'
    end

    # load all the stubs
    def self.client_side
        # this extension has not stub
        #require 'extensions/i2p/lib/stubs'
    end

    # constants
    PAYPAL_ORDERS_URL = "https://www.paypal.com"
    
    # static attributes
    @@paypal_business_email = nil # "sardi.leandro.daniel@gmail.com"
    @@paypal_orders_url = BlackStack::I2P::PAYPAL_ORDERS_URL
    @@paypal_ipn_listener = nil # "#{CS_HOME_WEBSITE}/api1.0/i2p/paypal/ipn.json"
    @@services_descriptor = []
    @@plans_descriptor = []
    
    # constant values for different type of plans (pay as you go, subscription)
    PAYMENT_PAY_AS_YOU_GO = 0
    PAYMENT_SUBSCRIPTION = 1

    # constant values for different type of consumtion (consume by unit, or consume by period of time)
    CONSUMPTION_BY_UNIT = 0 # el servicio se conume credito por credito. Ejemplo: lead records.
    CONSUMPTION_BY_TIME = 1 # el servicio exira al final del periodo de la factura. Ejemplos: Publicidad. Membresía.  

    # :mode may be :credits or :amount
    # if you choose :credits, the number of credits is shown in the header and in the transactions screen too.
    # if you choose :amount, the balance is shown in the header, and credits are hidden in the transactions screen.
    MODE_CREDITS = 0
    MODE_AMOUNT = 1

    #
    def self.payment_types()
      [PAYMENT_PAY_AS_YOU_GO, PAYMENT_SUBSCRIPTION]
    end

    def self.payment_type_description(type)
      return 'Pay as You Go' if type == PAYMENT_PAY_AS_YOU_GO
      return 'Subscription' if type == PAYMENT_SUBSCRIPTION
    end

    #
    def self.consumption_types()
      [CONSUMPTION_BY_UNIT, CONSUMPTION_BY_TIME]
    end

    def self.consumption_type_description(type)
      return 'Pay as You Go' if type == CONSUMPTION_BY_UNIT
      return 'Subscription' if type == CONSUMPTION_BY_TIME
    end

    # getters & setters
    def self.set(h)
      @@paypal_business_email = h['paypal_business_email'] if h.has_key?('paypal_business_email')
      @@paypal_orders_url = h['paypal_orders_url'] if h.has_key?('paypal_orders_url')
      @@paypal_ipn_listener = h['paypal_ipn_listener'] if h.has_key?('paypal_ipn_listener')
    end
      
    def self.set_paypal_business_email(email)
      @@paypal_business_email = email
    end # def self.set_paypal_business_email

    def self.paypal_business_email()
      @@paypal_business_email
    end # def self.set_paypal_business_email

    def self.paypal_orders_url()
      @@paypal_orders_url
    end
    
    def self.paypal_ipn_listener()
      @@paypal_ipn_listener
    end

    def self.set_services(h)
      @@services_descriptor = h
    end # def self.set_services

    def self.add_services(h)
      @@services_descriptor += h
    end # def self.set_services

    def self.services_descriptor()
      @@services_descriptor
    end # def self.services_descriptor
    
    def self.set_plans(h)
      @@plans_descriptor = h
    end # def self.set_plans

    def self.add_plans(h)
      @@plans_descriptor += h
    end # def self.set_plans

    def self.plans_descriptor()
      @@plans_descriptor
    end # def self.plans_descriptor

    def self.plan_descriptor(item_number)
      plan = BlackStack::I2P::plans_descriptor.select { |h| h[:item_number].to_s == item_number.to_s }.first
      #raise "Plan not found (#{item_number.to_s})" if plan.nil?
      plan
    end
  
    def self.service_descriptor(service_code)
      ret = BlackStack::I2P::services_descriptor.select { |h| h[:code] == service_code }.first
      #raise "Product not found" if ret.nil?
      ret 
    end
  end # module I2P
end # module BlackStack
