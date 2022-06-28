require_relative '../lib/i2p'
require_relative './conf'

# We'll create and simulate payments to an invoice with this ID.
# 
id_invoice = '71173f0f-5f2d-4b29-8a64-d002c3be8f23'
id_ipn = 'f79ac9b9-46ee-4fb9-980c-f511c877d209'

# Choose division to connect.
# 
BlackStack::Pampa::set_division_name(
  'copernico' # central database, where Payment sends all the IPNs
)

# Connect to database.
# 
DB = BlackStack::Pampa::db_connection

# Setup Sequel database classes.
#
BlackStack::Pampa::require_db_classes
BlackStack::InvoicingPaymentsProcessing::require_db_classes

# Load client 
#
c = BlackStack::Client.where(:api_key=>BlackStack::Pampa::api_key).first

# Notar que el numero de factura lleva anexionado el ID del cliente.
# 
invoice_number = "#{c.id.to_guid}.#{id_invoice.to_guid}"
subscr_id = 'I-U1VUKAX36LNE'

# Creo la IPN de forma ficticia, que registra la creacion de una nueva suscripcion de PayPal
#
h = {
  "id" => id_ipn, 
  "create_time" => '20191224150000', 
  "txn_type"=>"subscr_signup", 
  "subscr_id"=>subscr_id, 
  "last_name"=>"buyer", 
  "residence_country"=>"US", 
  "mc_currency"=>"USD", 
  "item_name"=>"Testing I2P", 
  "business"=>"sardi.leandro.daniel-facilitator@gmail.com", 
  "recurring"=>"1", 
  "verify_sign"=>"Aqi76kZ68ARsAHZ6RjFBtAnlrOAIA814FHvKpiTrXMo563uE5DHHkOwL", 
  "payer_status"=>"verified", 
  "test_ipn"=>"1", 
  "payer_email"=>"sardi.leandro.daniel-buyer@gmail.com", 
  "first_name"=>"test", 
  "receiver_email"=>"sardi.leandro.daniel-facilitator@gmail.com", 
  "payer_id"=>"P7DTDQPYAYZT8", 
  "invoice"=>invoice_number, 
  "reattempt"=>"1", 
  "item_number"=>"Testing.I2P", 
  "subscr_date"=>"10:02:55 Oct 26, 2018 PDT", 
  "charset"=>"windows-1252", 
  "notify_version"=>"3.9", 
#  "amount1"=>"1.00", 
#  "period1"=>"15 D", 
#  "mc_amount1"=>"1.00", 
  "amount3"=>"19.98", 
  "period3"=>"1 M", 
  "mc_amount3"=>"99.00", 
  "ipn_track_id"=>"ca8c4c88dc752"
}

# Proceso el IPN
# 
BlackStack::BufferPayPalNotification.process(h)
