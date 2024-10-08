module BlackStack
  module I2P
    class Subscription < Sequel::Model(:subscription)
      many_to_one :buffer_paypal_notification, :class=>:'BlackStack::I2P::BufferPayPalNotification', :key=>:id_buffer_paypal_notification
      many_to_one :account, :class=>:'BlackStack::I2P::Client', :key=>:id_account
      one_to_many :invoices, :class=>:'BlackStack::I2P::Invoice', :key=>:id_subscription
      
      # Returns an array of available payment types.
      # Currently supported types are :paypal and :manual.
      def self.types
        [:paypal, :manual]
      end

      # Returns an array of available colors associated with types.
      # Currently supported colors are :blue and :black.
      def self.colors
        [:blue, :black]
      end

      # ----------------------------------------------------------------------------------------- 
      # Factory
      # ----------------------------------------------------------------------------------------- 
      #
    
      # receive an IPN hash privided by PayPal. 
      # search an IPN by the keys that I conside are primary: verify_sign, txn_type, ipn_track_id.
      # if it founds the record in the table then it returns it, otherwise it returns nil. 
      def self.find(params)
        BlackStack::I2P::Subscription.where(
          :subscr_id=>params['subscr_id']
        ).first
      end

      # retorna true si existe un registro en :subscription con el mismo valor subscr_id.
      # sin retorna false.
      def self.load(params)
        BlackStack::I2P::Subscription.where(:subscr_id=>params['subscr_id']).first
      end
    
      # crea un nuevo objeto BufferPayPalNotification, y le mapea los atributos en el hash params.
      # no guarda el objeto en la base de datos.
      # retorna el objeto creado.
      def self.create(params)
        s = BlackStack::I2P::Subscription.new()
        s.subscr_id = params['subscr_id'].to_s
        s.last_name = params['last_name'].to_s
        s.residence_country = params['residence_country'].to_s
        s.mc_currency = params['mc_currency'].to_s
        #s.item_name = params['item_name'].to_s
        s.amount1 = params['amount1'].to_s
        s.business = params['business'].to_s
        s.amount3 = params['amount3'].to_s
        s.recurring = params['recurring'].to_s
        s.verify_sign = params['verify_sign'].to_s
        s.payer_status = params['payer_status'].to_s
        s.test_ipn = params['test_ipn'].to_s
        s.payer_email = params['payer_email'].to_s
        s.first_name = params['first_name'].to_s
        s.receiver_email = params['receiver_email'].to_s
        s.payer_id = params['payer_id'].to_s
        s.invoice = params['invoice'].to_s
        s.reattempt = params['reattempt'].to_s
        #s.item_number = params['item_number'].to_s
        s.subscr_date = params['subscr_date'].to_s
        s.charset = params['charset'].to_s
        s.notify_version = params['notify_version'].to_s
        s.period1 = params['period1'].to_s
        s.mc_amount1 = params['mc_amount1'].to_s
        s.period3 = params['period3'].to_s
        s.mc_amount3 = params['mc_amount3'].to_s
        s.ipn_track_id = params['ipn_track_id'].to_s
        s
      end
    
      # retorna un hash descriptor de este objecto
      def to_hash()
        ret = {}
        # campos de uso interno
        ret['id'] = self.id 
        ret['create_time'] = self.create_time.datetime_sql_to_api 
        ret['id_account'] = self.id_account 
        ret['id_buffer_paypal_notification'] = self.id_buffer_paypal_notification 
        ret['active'] = self.active 
        # vinculacion a objetos
        ret['id_pipeline'] = self.id_pipeline 
        ret['id_lngroup'] = self.id_lngroup 
        ret['id_crmlist'] = self.id_crmlist
        # campos replicados del ipn
        ret['subscr_id'] = self.subscr_id 
        ret['last_name'] = self.last_name 
        ret['residence_country'] = self.residence_country 
        ret['mc_currency'] = self.mc_currency
        #ret['item_name'] = self.item_name
        ret['amount1'] = self.amount1
        ret['business'] = self.business 
        ret['amount3'] = self.amount3 
        ret['recurring'] = self.recurring 
        ret['verify_sign'] = self.verify_sign 
        ret['payer_status'] = self.payer_status 
        ret['test_ipn'] = self.test_ipn
        ret['payer_email'] = self.payer_email 
        ret['first_name'] = self.first_name 
        ret['receiver_email'] = self.receiver_email 
        ret['payer_id'] = self.payer_id
        ret['invoice'] = self.invoice 
        ret['reattempt'] = self.reattempt 
        #ret['item_number'] = self.item_number 
        ret['subscr_date'] = self.subscr_date 
        ret['charset'] = self.charset
        ret['notify_version'] = self.notify_version 
        ret['period1'] = self.period1
        ret['mc_amount1'] = self.mc_amount1 
        ret['period3'] = self.period3
        ret['mc_amount3'] = self.mc_amount3 
        ret['ipn_track_id'] = self.ipn_track_id 
        ret
      end
    
      # TODO: deprecated
      # Retorna el objeto vinculado a esta suscripcion
      def assignedObject()
        if (self.item_number =~ /^#{PRODUCT_SSM}\./)
          return self.pipeline
        elsif (self.item_number =~ /^#{PRODUCT_FLD}\./)
          return self.crmlist
        elsif (self.item_number =~ /^#{PRODUCT_IPJ}\./)
          return self.lngroup
        else # unknown
          return nil
        end
      end
      
      # retorna un array con facturas de esta suscripcion
      def invoices()
        a = []
        if self.subscr_id.to_s.size > 0
          DB[
          "SELECT DISTINCT i.id " +
          "FROM invoice i " + 
          "WHERE i.subscr_id='#{self.subscr_id.to_s}' "
          ].all { |row|
            a << BlackStack::I2P::Invoice.where(:id=>row[:id]).first
            # release resources 
            DB.disconnect
            GC.start
          }      
        end
        a
      end # def invoices
    
    end # class Subscription
  end # module I2P
end # module BlackStack