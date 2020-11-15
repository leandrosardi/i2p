require 'blackstack_commons'
require 'pampa_workers'

# 
# 
# 
module BlackStack
  
  module InvoicingPaymentsProcessing
    
    # constants
    PAYPAL_ORDERS_URL = "https://www.paypal.com"
    
    # static attributes
    @@paypal_business_email = "sardi.leandro.daniel@gmail.com"
    @@paypal_orders_url = BlackStack::InvoicingPaymentsProcessing::PAYPAL_ORDERS_URL
    @@paypal_ipn_listener = "#{BlackStack::Pampa::api_url.to_s}/api1.3/accounting/paypal/notify_new_invoice.json"

    @@products_descriptor = []
    @@plans_descriptor = []
    
    # getters & setters
    def self.set_config(h)
      @@paypal_business_email = h[:paypal_business_email]
      @@paypal_orders_url = h[:paypal_orders_url]
      @@paypal_ipn_listener = h[:paypal_ipn_listener]
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


    def self.set_products(h)
      @@products_descriptor = h
    end # def self.set_products

    def self.products_descriptor()
      @@products_descriptor
    end # def self.products_descriptor
    

    def self.set_plans(h)
      @@plans_descriptor = h
    end # def self.set_plans

    def self.plans_descriptor()
      @@plans_descriptor
    end # def self.plans_descriptor


    def self.plan_descriptor(item_number)
      plan = BlackStack::InvoicingPaymentsProcessing::plans_descriptor.select { |h| h[:item_number].to_s == item_number.to_s }.first
      raise "Plan not found (#{item_number.to_s})" if plan.nil?
      plan
    end
  
    def self.product_descriptor(product_code)
      ret = BlackStack::InvoicingPaymentsProcessing::products_descriptor.select { |h| h[:code] == product_code }.first
      raise "Product not found" if ret.nil?
      ret 
    end


    def self.require_db_classes()
      # You have to load all the Sinatra classes after connect the database.
      require_relative '../lib/balance.rb'
      require_relative '../lib/bufferpaypalnotification.rb'
      require_relative '../lib/customplan.rb'
      require_relative '../lib/invoice.rb'
      require_relative '../lib/invoiceitem.rb'
      require_relative '../lib/movement.rb'
      require_relative '../lib/paypalsubscription.rb'
      require_relative '../lib/extend_client_by_invoicing_payments_processing.rb'
    end

    class BasePlan
      PAYMENT_PAY_AS_YOU_GO = 'G'
      PAYMENT_SUBSCRIPTION = 'S'

      CONSUMPTION_BY_UNIT = 0 # el producto se conume credito por credito. Ejemplo: lead records.
      CONSUMPTION_BY_TIME = 1 # el producto exira al final del periodo de la factura. Ejemplos: Publicidad. Membresía.  

      PRODUCT_WAREHOUSE = 'Warehouse Service'
      PRODUCT_SOFTWARE = 'Software Service'
      PRODUCT_AGENCY = 'Agency Service'
      PRODUCT_EDUCATION = 'Education Service'
      PRODUCT_OTHER = 'Other Service'
  
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

      # 
      def self.product_types()
        [PRODUCT_WAREHOUSE, PRODUCT_SOFTWARE, PRODUCT_AGENCY, PRODUCT_EDUCATION, PRODUCT_OTHER]  
      end

      def self.product_type_icon(s)
        return "icon-cloud" if s == PRODUCT_WAREHOUSE
        return "icon-desktop" if s == PRODUCT_SOFTWARE
        return "icon-coffee" if s == PRODUCT_AGENCY 
        return "icon-book" if s == PRODUCT_EDUCATION
        return "icon-help" if s == PRODUCT_OTHER
      end


    end # class BasePlan
     
  end # module InvoicingPaymentsProcessing
  
end # module BlackStack
