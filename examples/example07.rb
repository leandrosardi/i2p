require_relative '../lib/i2p'
require_relative './conf'

# We'll create and simulate payments to an invoice with this ID.
# 
id_invoice = '71173f0f-5f2d-4b29-8a64-d002c3be8f23'
id_ipn = 'b540b545-c612-4b61-bc6f-0f4f34a64078'

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

# Creo la IPN de forma ficticia, que registra el primer pago de una suscripcion de PayPal. 
#
h = {
  "id" => id_ipn, 
  "create_time" => '20191224150000', 
  "transaction_subject"=>"SocialSellingMachine Program - Robin Plan - 25 Leads/mo.", 
  "payment_date"=>"08:42:17 Oct 26, 2018 PDT", 
  "txn_type"=>"subscr_payment", 
  "subscr_id"=>subscr_id, 
  "last_name"=>"buyer", 
  "residence_country"=>"US", 
  "item_name"=>"SocialSellingMachine Program - Robin Plan - 25 Leads/mo.", 
  "payment_gross"=>"19.98", 
  "mc_currency"=>"USD", 
  "business"=>"sardi.leandro.daniel-facilitator@gmail.com", 
  "payment_type"=>"instant", 
  "protection_eligibility"=>"Eligible", 
  "verify_sign"=>"AIls.0ayavTd.bLosRxHvtPQWk8-AtYM5tj8zGoatWFA-dwe06j2PQ8p", 
  "payer_status"=>"verified", 
  "test_ipn"=>"1", 
  "payer_email"=>"sardi.leandro.daniel-buyer@gmail.com", 
  "txn_id"=>"1X8745646Y0802355", 
  "receiver_email"=>"sardi.leandro.daniel-facilitator@gmail.com", 
  "first_name"=>"test", 
  "invoice"=>invoice_number, 
  "payer_id"=>"P7DTDQPYAYZT8", 
  "receiver_id"=>"KMNFGW7BAZSVA", 
  "item_number"=>"SSM.Robin-Monthly", 
  "payment_status"=>"Completed", 
  "payment_fee"=>"5.99", 
  "mc_fee"=>"5.99", 
  "mc_gross"=>"19.98", 
  "charset"=>"windows-1252", 
  "notify_version"=>"3.9", 
  "ipn_track_id"=>"43b9a672808ba"
}

# Proceso el IPN
# 
BlackStack::BufferPayPalNotification.process(h)
