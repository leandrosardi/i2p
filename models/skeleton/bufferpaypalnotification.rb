module BlackStack
  module I2P  
    class BufferPayPalNotification < Sequel::Model(:buffer_paypal_notification)    
      TXN_STATUS_CENCELED_REVERSAL = "Canceled_Reversal" # reembolso hecho por PayPal, luego de una disputa
      TXN_STATUS_COMPLETED = "Completed"
      TXN_STATUS_FAILED = "Failed"
      TXN_STATUS_PENDING = "Pending"
      TXN_STATUS_REFUNDED = "Refunded"
      TXN_STATUS_REVERSED = "Reversed"
    
      TXN_TYPE_SUBSCRIPTION_SIGNUP = "subscr_signup"
      TXN_TYPE_SUBSCRIPTION_PAYMENT = "subscr_payment"
      TXN_TYPE_SUBSCRIPTION_CANCEL = "subscr_cancel"
      TXN_TYPE_SUBSCRIPTION_FAILED = "subscr_failed"
      TXN_TYPE_SUBSCRIPTION_REFUND = ""
      TXN_TYPE_SUBSCRIPTION_MODIFY = "subscr_modify"
      TXN_TYPE_SUBSCRIPTION_SUSPEND = "recurring_payment_suspended"
      TXN_TYPE_SUBSCRIPTION_SUSPEND_DUE_MAX_FAILURES = "recurring_payment_suspended_due_to_max_failed_payment"
      TXN_TYPE_WEB_ACCEPT = "web_accept" # one time payment
      # TXN_TYPE_SUBSCRIPTION_EOT = "subscr_eot" # no sabemos para que es esto
      
      PAYMENT_STATUS_COMPLETED = "Completed"
          
      def isSubscription?
        self.txn_type =~ /^subscr_/
      end
    
      def self.revenue
        DB["
          SELECT COALESCE(SUM(CAST(payment_gross AS NUMERIC(18,4))),0) AS revenue 
          FROM buffer_paypal_notification 
          WHERE txn_type='#{BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_PAYMENT}'
        "].first[:revenue]
      end

      # get the id of the first invoice of the series of IPNs that started with the same invoice.
      # el campo `invoice` tiene formato "cid.iid"
      def first_invoice_id
        self.invoice.split(/\./).last 
      end

      # Return the first invoice who started this series of IPNs,
      # by matching the id of the invoice with the the `invoice` of the IPN. 
      #
      # This method is useful when you manage subscriptions, and you start getting 
      # further IPNs with the same value in the `invoice` field but regarding different
      # records in the invoice table.
      # 
      def first_invoice
        i = nil
        iid = self.invoice.split(".").last.to_s
        i = BlackStack::I2P::Invoice.where(:id=>iid).first if iid.guid?
        i
      end

      # find the account linked with this IPN, by fiding the `first_invoice` of the IPN first.
      def account
        i = self.first_invoice
        i.nil? ? nil : i.account
      end
      
      # receive an IPN hash privided by PayPal. 
      # search an IPN by the keys that I conside are primary: verify_sign, txn_type, ipn_track_id.
      # if it founds the record in the table then it returns it, otherwise it returns nil. 
      def self.find(params)
        BlackStack::I2P::BufferPayPalNotification.where(
          :verify_sign=>params['verify_sign'], 
          :txn_type=>params['txn_type'], 
          :ipn_track_id=>params['ipn_track_id']
        ).first
      end
    
      # receive an IPN hash privided by PayPal. 
      # search an IPN by the keys that I conside are primary: verify_sign, txn_type, ipn_track_id.
      # if it founds the record in the table then it returns true, otherwise it returns false.
      def self.exists?(params)
        !BlackStack::I2P::BufferPayPalNotification.find(params).nil?
      end

      # receive an IPN hash privided by PayPal. 
      # crea un nuevo objeto BufferPayPalNotification, y le mapea los atributos en el hash params.
      # no guarda el objeto en la base de datos.
      # retorna el objeto creado.
      def initialize(params)
          super()
          self.id = guid
          self.create_time = now
          self.txn_type = params['txn_type'].to_s
          self.subscr_id = params['subscr_id'].to_s
          self.last_name = params['last_name'].to_s
          self.residence_country = params['residence_country'].to_s
          self.mc_currency = params['mc_currency'].to_s
          self.item_name = params['item_name'].to_s
          self.amount1 = params['amount1'].to_s
          self.business = params['business'].to_s
          self.amount3 = params['amount3'].to_s
          self.recurring = params['recurring'].to_s
          self.verify_sign = params['verify_sign'].to_s
          self.payer_status = params['payer_status'].to_s
          self.test_ipn = params['test_ipn'].to_s
          self.payer_email = params['payer_email'].to_s
          self.first_name = params['first_name'].to_s
          self.receiver_email = params['receiver_email'].to_s
          self.payer_id = params['payer_id'].to_s
          self.invoice = params['invoice'].to_s
          self.reattempt = params['reattempt'].to_s
          self.item_number = params['item_number'].to_s
          self.subscr_date = params['subscr_date'].to_s
          self.charset = params['charset'].to_s
          self.notify_version = params['notify_version'].to_s
          self.period1 = params['period1'].to_s
          self.mc_amount1 = params['mc_amount1'].to_s
          self.period3 = params['period3'].to_s
          self.mc_amount3 = params['mc_amount3'].to_s
          self.ipn_track_id = params['ipn_track_id'].to_s
          self.transaction_subject = params['transaction_subject'].to_s
          self.payment_date = params['payment_date'].to_s
          self.payment_gross = params['payment_gross'].to_s
          self.payment_type = params['payment_type'].to_s
          self.txn_id = params['txn_id'].to_s
          self.receiver_id = params['receiver_id'].to_s
          self.payment_status = params['payment_status'].to_s
          self.payment_fee = params['payment_fee'].to_s
          self
      end
        
      def to_hash()
        ret = {}
        ret['id'] = self.id 
        ret['create_time'] = self.create_time.to_api
        ret['txn_type'] = self.txn_type 
        ret['subscr_id'] = self.subscr_id 
        ret['last_name'] = self.last_name 
        ret['residence_country'] = self.residence_country 
        ret['mc_currency'] = self.mc_currency
        ret['item_name'] = self.item_name
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
        ret['item_number'] = self.item_number 
        ret['subscr_date'] = self.subscr_date 
        ret['charset'] = self.charset
        ret['notify_version'] = self.notify_version 
        ret['period1'] = self.period1
        ret['mc_amount1'] = self.mc_amount1 
        ret['period3'] = self.period3
        ret['mc_amount3'] = self.mc_amount3 
        ret['ipn_track_id'] = self.ipn_track_id 
        ret['transaction_subject'] = self.transaction_subject 
        ret['payment_date'] = self.payment_date
        ret['payment_gross'] = self.payment_gross 
        ret['payment_type'] = self.payment_type 
        ret['txn_id'] = self.txn_id 
        ret['receiver_id'] = self.receiver_id 
        ret['payment_status'] = self.payment_status 
        ret['payment_fee'] = self.payment_fee
        ret
      end
    
      # receive an IPN hash privided by PayPal.
      # salda facturas
      # si se trata de una suscripcion, entonces genera nuevas facturas para pagos futuros
      def process 
          # validation: if this IPN is already linked to an invoice, then ignore it.
        if BlackStack::I2P::Invoice.where(:id_buffer_paypal_notification=>self.id).first.nil?

          # validation: the IPN must be linked to an account
          a = self.account
          if a.nil?
            raise "Client not found (payer_email=#{self.payer_email.to_s})."
          end
          
          # parseo en numero de factura formado por id_account.id_invoice
          cid = a.id.to_guid
          iid = self.first_invoice_id
      
          # si es un pago por un primer trial, sengundo trial o pago recurrente de suscripcion,
          # entonces registro la factura, activo el rol de este cliente (deprecated), se agrega el cliente a la lista de emails (deprecated)
          if  ( ( self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_WEB_ACCEPT || self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_PAYMENT || self.txn_type == BufferPayPalNotification::TXN_STATUS_COMPLETED ) && self.payment_status == 'Completed' )        
            # reviso si la factura ya estaba creada.
            # la primer factura se por adelantado cuando el cliente hace signup, y antes de que se suscriba a paypal, y se le pone un ID igual a primer GUID del campo invoice del IPN
            i = BlackStack::I2P::Invoice.where(:id=>iid, :status=>BlackStack::I2P::Invoice::STATUS_UNPAID).order(:billing_period_from).first
            if i.nil?
              i = BlackStack::I2P::Invoice.where(:id=>iid, :status=>nil).order(:billing_period_from).first
            end
            
            # de la segunda factura en adelante, se generan con un ID diferente, pero se le guarda a subscr_id para identificar cuado llegue el pago de esa factura
            if i.nil?
              # busco una factura en estado UNPAID que este vinculada a esta suscripcion
              q = "
                SELECT i.id AS iid 
                FROM invoice i 
                WHERE i.id_account='#{cid}' 
                AND COALESCE(i.status,#{BlackStack::I2P::Invoice::STATUS_UNPAID})=#{Invoice::STATUS_UNPAID} 
                AND i.subscr_id = '#{self.subscr_id}'
                ORDER BY i.billing_period_from ASC
                LIMIT 1
              "
              row = DB[q].first
              if row != nil
                i = BlackStack::I2P::Invoice.where(:id=>row[:iid]).first
              end

              # si la factura no existe, entonces la creo
              if i.nil?
                # busco la ultima factura de este cliente, con el mismo subscription id
                # reference: https://github.com/leandrosardi/cs/issues/61
                i = BlackStack::I2P::Invoice.where(:id_account=>cid, :subscr_id=>self.subscr_id).order(:billing_period_from).last
                if i.nil?
                  raise "Invoice not found"
                end
                # creo una nueva factura para el periodo siguiente
                j = BlackStack::I2P::Invoice.new()
                j.id = guid()
                j.id_account = a.id
                j.create_time = now()
                j.disabled_trial = a.disabled_trial
                j.save()
                j.next(i)
                i = j
              end
            end
          
            # valido que el importe de la factura sea igual al importe del IPN
            raise "Invoice amount is not the equal to the amount of the IPN (#{i.total.to_s}!=#{self.payment_gross.to_s})" if i.total.to_f != self.payment_gross.to_f
      
            # le asigno el id_buffer_paypal_notification
            i.id_buffer_paypal_notification = self.id
            i.subscr_id = self.subscr_id
            i.save
        
            # marco la factura como pagada
            # registro contable - bookkeeping
            i.getPaid(self.create_time) if i.canBePaid?
        
            # crea una factura para el periodo siguiente (dia, semana, mes, anio)
            j = BlackStack::I2P::Invoice.new()
            j.id = guid()
            j.id_account = a.id
            j.create_time = now()
            j.disabled_trial = a.disabled_trial
            j.save()
        
            # genero los datos de esta factura, como la siguiente factura a la que estoy pagando en este momento
            j.next(i)

          elsif (self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SIGNUP)
            # crear un registro en la tabla subscriptions
            if BlackStack::I2P::Subscription.find(self.to_hash) != nil
              # mensaje de error
              raise 'Subscription Already Exists.'
            else
              # registro la suscripcion en la base de datos
              s = BlackStack::I2P::Subscription.create(self.to_hash)
              s.id = guid
              s.id_buffer_paypal_notification = self.id
              s.create_time = now       
              s.id_account = a.id
              s.active = true
              s.save              
              # obtengo la factura que se creo con esta suscripcion
              i = BlackStack::I2P::Invoice.where(:id=>iid).first
              # vinculo esta suscripcion a la factura que la genero, y a todas las facturas siguientes
              i.set_subscription(s)
            end
              
          elsif (
            self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_CANCEL #||
            #self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SUSPEND ||           # estos IPN traen el campo subscr_id en blanco
            #self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SUSPEND_DUE_MAX_FAILURES   # estos IPN traen el campo subscr_id en blanco
          )
              s = BlackStack::I2P::Subscription.find(self.to_hash)
              if s.nil?
                # validate: subscription exists
                raise "Subscription (#{self.subscr_id}) Not Found."
              else
                # registro la suscripcion en la base de datos
                s.active = false
                s.save
              end
        
          elsif (self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_FAILED)
            # TODO: actualizar registro en la tabla subscriptions. notificar al usuario
        
          elsif (self.txn_type == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_MODIFY)
            # TODO: ?
        
          elsif (self.txn_type.to_s == BlackStack::I2P::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_REFUND)
            # PROBLEMA: Los IPN no dicen de a quÃ© pago corresponde el reembolso
              
            payment_gross = 0
            if self.payment_status == BlackStack::I2P::BufferPayPalNotification::TXN_STATUS_CENCELED_REVERSAL
              payment_gross = 0 - self.payment_gross.to_f - self.payment_fee.to_f 
            elsif self.payment_status == BlackStack::I2P::BufferPayPalNotification::TXN_STATUS_REFUNDED || self.payment_status == BlackStack::I2P::BufferPayPalNotification::TXN_STATUS_REVERSED
              payment_gross = self.payment_gross.to_f # en negativo 
            end
            if payment_gross < 0
              # validation: verifico que la factura por este IPN no exista
              j = BlackStack::I2P::Invoice.where(:id_buffer_paypal_notification=>self.id).first
              if !j.nil?
                raise 'Invoice already exists.'
              end
                
              # obtengo la ultima factura pagada, vinculada a un IPN con el mismo codigo invoice
              row = DB["
                SELECT i.id 
                FROM buffer_paypal_notification b 
                JOIN invoice i ON ( b.id=i.id_buffer_paypal_notification AND i.status=#{BlackStack::I2P::Invoice::STATUS_PAID.to_s} ) 
                WHERE b.invoice='#{self.invoice}' 
                ORDER BY i.create_time DESC 
                LIMIT 1
              "].first
              if row.nil?
                raise 'Previous Paid Invoice not found.'
              end
              k = BlackStack::I2P::Invoice.where(:id=>row[:id]).first
                
              # creo la factura por el reembolso
              k.refund(payment_gross)  
            end
          else
            # unknown
          end
        end # if i.nil?
      end # def process
    end # class
  end # module I2P
end # module BlackStack