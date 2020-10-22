module BlackStack  
  class BufferPayPalNotification < Sequel::Model(:buffer_paypal_notification)
    BlackStack::BufferPayPalNotification.dataset = BlackStack::BufferPayPalNotification.dataset.disable_insert_output
    self.dataset = self.dataset.disable_insert_output
  
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
  
    LOCKING_FILENAME = "./accounting.bufferpaypalnotification.lock"  
    LOGGING_FILENAME = "./accounting.bufferpaypalnotification.log"  
    @@fd = File.open(LOCKING_FILENAME,"w")
  
    def isSubscription?
      self.txn_type =~ /^subscr_/
    end
  
    def self.revenue()
      DB["SELECT ISNULL(SUM(CAST(payment_gross AS NUMERIC(18,4))),0) AS revenue FROM buffer_paypal_notification WITH (NOLOCK) WHERE txn_type='#{BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_PAYMENT}'"].first[:revenue]
    end
  
    # busca al cliente relacionado con este pago, de tres formas:
    # 1) haciendo coincidir el campo client.paypal_email con el BlackStack::BufferPayPalNotification.payer_email
    # 2) haciendo coincidir el campo user.email con el BlackStack::BufferPayPalNotification.payer_email
    # 3) haciendo coincidir el campo payer_email de alguna suscripcion existente con el BlackStack::BufferPayPalNotification.payer_email
    # 3) haciendo coincidir el primer guid en el codigo de invoice, con el id del cliente
    def get_client()
      # obtengo el cliente que machea con este perfil
      c = nil
      if c.nil?
        if self.invoice.guid?
          i = BlackStack::Invoice.where(:id=>self.invoice).first
          c = i.client if !i.nil? 
        end
      end
      if c.nil?
        cid = self.invoice.split(".").first.to_s
        if cid.guid?
          c = BlackStack::Client.where(:id=>cid).first
        end
      end
      if c.nil?
        c = BlackStack::Client.where(:paypal_email=>self.payer_email).first
        if (c == nil)
          u = User.where(:email=>self.payer_email).first
          if (u!=nil)
            c = u.client
          end
        end
      end
      if c.nil?
        s = BlackStack::PayPalSubscription.where(:payer_email=>self.payer_email).first
        if (s!=nil)
          c = s.client
        end
      end
      if c.nil?
        # obtengo el cliente - poco elegante
        q = 
        "SELECT TOP 1 i.id_client AS cid " +
        "FROM buffer_paypal_notification b WITH (NOLOCK) " +
        "JOIN invoice i WITH (NOLOCK) ON b.id=i.id_buffer_paypal_notification " +
        "WHERE b.id<>'#{self.id}' AND b.payer_id = '#{self.payer_id}' "
        row = DB[q].first       
        if (row!=nil)
          # obtengo el cliente al que corresponde este IPN
          c = BlackStack::Client.where(:id=>row[:cid]).first
        end
      end
      c
    end
  
    def self.lock()
      @@fd.flock(File::LOCK_EX)
    end
  
    def self.release()
      @@fd.flock(File::LOCK_UN)
    end
  
  
    # ----------------------------------------------------------------------------------------- 
    # Factory
    # ----------------------------------------------------------------------------------------- 
  
    def self.load(params)
      BlackStack::BufferPayPalNotification.where(
        :verify_sign=>params['verify_sign'], 
        :txn_type=>params['txn_type'], 
        :ipn_track_id=>params['ipn_track_id']
      ).first
    end
  
    # crea un nuevo objeto BufferPayPalNotification, y le mapea los atributos en el hash params.
    # no guarda el objeto en la base de datos.
    # retorna el objeto creado.
    def self.create(params)
        b = BlackStack::BufferPayPalNotification.new()
        b.txn_type = params['txn_type'].to_s
        b.subscr_id = params['subscr_id'].to_s
        b.last_name = params['last_name'].to_s
        b.residence_country = params['residence_country'].to_s
        b.mc_currency = params['mc_currency'].to_s
        b.item_name = params['item_name'].to_s
        b.amount1 = params['amount1'].to_s
        b.business = params['business'].to_s
        b.amount3 = params['amount3'].to_s
        b.recurring = params['recurring'].to_s
        b.verify_sign = params['verify_sign'].to_s
        b.payer_status = params['payer_status'].to_s
        b.test_ipn = params['test_ipn'].to_s
        b.payer_email = params['payer_email'].to_s
        b.first_name = params['first_name'].to_s
        b.receiver_email = params['receiver_email'].to_s
        b.payer_id = params['payer_id'].to_s
        b.invoice = params['invoice'].to_s
        b.reattempt = params['reattempt'].to_s
        b.item_number = params['item_number'].to_s
        b.subscr_date = params['subscr_date'].to_s
        b.charset = params['charset'].to_s
        b.notify_version = params['notify_version'].to_s
        b.period1 = params['period1'].to_s
        b.mc_amount1 = params['mc_amount1'].to_s
        b.period3 = params['period3'].to_s
        b.mc_amount3 = params['mc_amount3'].to_s
        b.ipn_track_id = params['ipn_track_id'].to_s
        b.transaction_subject = params['transaction_subject'].to_s
        b.payment_date = params['payment_date'].to_s
        b.payment_gross = params['payment_gross'].to_s
        b.payment_type = params['payment_type'].to_s
        b.txn_id = params['txn_id'].to_s
        b.receiver_id = params['receiver_id'].to_s
        b.payment_status = params['payment_status'].to_s
        b.payment_fee = params['payment_fee'].to_s
        b
    end
  
    # segun los atributos en el hash params, obtiene el objeto BufferPayPalNotification de a base de datos.
    # si el objeto no existe, entonces crea un nuevo registro en la base de datos.
    #
    # este metodo es invocado desde el access point que recive las notificaciones de PayPal. 
    # por lo tanto, ejecuta mecanismos de bloqueo para manejar la concurrencia.
    #
    # retorna el objeto creado o cargado de la base de datos.
    def self.parse(params)
      begin
        # Levantar el flag de reserva a mi favor
        self.lock()
    
        # escribo la notificacion cruda en un archivo de log, en caso que falle el mapeo a la base de datos por error del programador
        File.open(LOGGING_FILENAME, 'a') { |file| file.puts(params.to_s) }
    
        # si la notificacion no existe en la base de datos, la inserto
        # si la notificacion ya existe entonces la actualizo, porque puede tratarse de un pago que no se habia podido completar (payment_status=='Completed')
        b = BlackStack::BufferPayPalNotification.load(params)
        if (b==nil)
          b = self.create(params)
          b.id = guid
          b.create_time = now
          b.save
        end      
    
        # desbloquear
        self.release()
        
        return b
    rescue => e
        # ante cualquier falla, lo primero es desbloquear
        self.release()
        raise e
      end
    end # self.parse
  
  
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
  
    # salda facturas
    # genera nuevas facturas para pagos futuros
    def self.process(params)
      DB.transaction do
        # verifico que no existe ya una notificacion
#puts
#puts 
#puts "params2:#{params.to_s}:."
        b = BlackStack::BufferPayPalNotification.where(:id=>params['id']).first
        if b.nil?
          # proceso la notificacion
          b = BlackStack::BufferPayPalNotification.create(params)
          # inserto la notificacion en la base de datos
          b.id = params['id']
          b.create_time = params['create_time'].api_to_sql_datetime
          b.save
        end
        
        if !BlackStack::Invoice.where(:id_buffer_paypal_notification=>b.id).first.nil?
          raise "IPN already linked to an invoice."
        end
    
        # varifico que el cliente exista
        c = b.get_client
        if c.nil?
          raise "Client not found (payer_email=#{b.payer_email.to_s})."
        end
  
        # parseo en nuemero de factura formado por id_client.id_invoice
        cid = c.id.to_guid
        iid = b.invoice.split(/\./).last # NOTA: el campo invoice tiene formato "cid.iid", pero originalmente solo tenia el formato "iid" 
  
        # si es un pago por un primer trial, sengundo trial o pago recurrente de suscripcion,
        # entonces registro la factura, activo el rol de este cliente (deprecated), se agrega el cliente a la lista de emails (deprecated)
        if  ( ( b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_WEB_ACCEPT || b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_PAYMENT || b.txn_type == BufferPayPalNotification::TXN_STATUS_COMPLETED ) && b.payment_status == 'Completed' )        
          # reviso si la factura ya estaba creada.
          # la primer factura se por adelantado cuando el cliente hace signup, y antes de que se suscriba a paypal, y se le pone un ID igual a primer GUID del campo invoice del IPN
          i = BlackStack::Invoice.where(:id=>iid, :status=>BlackStack::Invoice::STATUS_UNPAID).order(:billing_period_from).first
          if i.nil?
            i = BlackStack::Invoice.where(:id=>iid, :status=>nil).order(:billing_period_from).first
          end
          
          # de la segunda factura en adelante, se generan con un ID diferente, pero se le guarda a subscr_id para identificar cuado llegue el pago de esa factura
          if i.nil?
            # busco una factura en estado UNPAID que este vinculada a esta suscripcion
            q =
            "SELECT TOP 1 i.id AS iid " + 
            "FROM invoice i WITH (NOLOCK) " +
            "WHERE i.id_client='#{cid}' " +
            "AND ISNULL(i.status,#{BlackStack::Invoice::STATUS_UNPAID})=#{Invoice::STATUS_UNPAID} " +
            "AND i.subscr_id = '#{b.subscr_id}' " +
            "ORDER BY i.billing_period_from ASC "
            row = DB[q].first
            if row != nil
              i = BlackStack::Invoice.where(:id=>row[:iid]).first
            end
          end
  
          # valido haber encontrado la factura
          raise "Invoice not found" if i.nil?
  
          # valido que el importe de la factura sea igual al importe del IPN
          raise "Invoice amount is not the equal to the amount of the IPN (#{i.total.to_s}!=#{b.payment_gross.to_s})" if i.total.to_f != b.payment_gross.to_f
  
          # le asigno el id_buffer_paypal_notification
          i.id_buffer_paypal_notification = b.id
					i.subscr_id = b.subscr_id
          i.save
    
          # marco la factura como pagada
          # registro contable - bookkeeping
          i.getPaid(b.create_time) if i.canBePaid?
    
          # crea una factura para el periodo siguiente (dia, semana, mes, anio)
          j = BlackStack::Invoice.new()
          j.id = guid()
          j.id_client = c.id
          j.create_time = now()
          j.disabled_for_trial_ssm = c.disabled_for_trial_ssm
          j.save()
    
          # genero los datos de esta factura, como la siguiente factura a la que estoy pagando en este momento
          j.next(i)
          
          # creo el milestone con todo el credito pendiente que tiene esta subscripcion
          buff_payment = i.buffer_paypal_notification
          buff_signup = BlackStack::BufferPayPalNotification.where(:txn_type=>"subscr_signup", :subscr_id=>buff_payment.subscr_id).first
          subs = buff_signup == nil ? nil : BlackStack::PayPalSubscription.where(:id_buffer_paypal_notification => buff_signup.id).first
              
        elsif (b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SIGNUP)
          # crear un registro en la tabla paypal_subscriptions
          if BlackStack::PayPalSubscription.load(b.to_hash) != nil
            # mensaje de error
            raise 'Subscription Already Exists.'
          else
            # registro la suscripcion en la base de datos
            s = BlackStack::PayPalSubscription.create(b.to_hash)
            s.id = guid
            s.id_buffer_paypal_notification = b.id
            s.create_time = now       
            s.id_client = c.id
            s.active = true
            s.save
            
            # obtengo la factura que se creo con esta suscripcion
            i = BlackStack::Invoice.where(:id=>b.item_number).first
            
            # vinculo esta suscripcion a la factura que la genero, y a todas las facturas siguientes
            i.set_subscription(s)
          end
          
        elsif (
          b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_CANCEL #||
          #b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SUSPEND ||           # estos IPN traen el campo subscr_id en blanco
          #b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_SUSPEND_DUE_MAX_FAILURES   # estos IPN traen el campo subscr_id en blanco
        )
          s = BlackStack::PayPalSubscription.load(b.to_hash)
          if s.nil?
            # mensaje de error
            raise "Subscription (#{b.subscr_id}) Not Found."
          else
            # registro la suscripcion en la base de datos
            s.active = false
            s.save
          end
    
        elsif (b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_FAILED)
          # TODO: actualizar registro en la tabla paypal_subscriptions. notificar al usuario
    
        elsif (b.txn_type == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_MODIFY)
          # TODO: ?
    
        elsif (b.txn_type.to_s == BlackStack::BufferPayPalNotification::TXN_TYPE_SUBSCRIPTION_REFUND)
          # PROBLEMA: Los IPN no dicen de a quÃ© pago corresponde el reembolso
          
          payment_gross = 0
          if b.payment_status == BlackStack::BufferPayPalNotification::TXN_STATUS_CENCELED_REVERSAL
            payment_gross = 0 - b.payment_gross.to_f - b.payment_fee.to_f 
          elsif b.payment_status == BlackStack::BufferPayPalNotification::TXN_STATUS_REFUNDED || b.payment_status == BlackStack::BufferPayPalNotification::TXN_STATUS_REVERSED
            payment_gross = b.payment_gross.to_f # en negativo 
          end
          if payment_gross < 0
            # verifico que la factura por este IPN no exista
            j = BlackStack::Invoice.where(:id_buffer_paypal_notification=>b.id).first
            if (j!=nil)
              raise 'Invoice already exists.'
            end
            
            # obtengo la ultima factura pagada, vinculada a un IPN con el mismo codigo invoice
            row = DB[
              "SELECT TOP 1 i.id " +
              "FROM buffer_paypal_notification b " +
              "JOIN invoice i ON ( b.id=i.id_buffer_paypal_notification AND i.status=#{BlackStack::Invoice::STATUS_PAID.to_s} ) " +
              "WHERE b.invoice='#{b.invoice}' " +
              "ORDER BY i.create_time DESC "
            ].first
            if row.nil?
              raise 'Previous Paid Invoice not found.'
            end
            k = BlackStack::Invoice.where(:id=>row[:id]).first
            
            # creo la factura por el reembolso
            k.refund(payment_gross)  
          end
        else
          # unknown
          
        end
      end # DB.transaction
    end # def process
  end # class
end # module BlackStack