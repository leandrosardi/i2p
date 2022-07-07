# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/i2p'

# find the latest created invoice, and its associated account
i = BlackStack::I2P::Invoice.order(:create_time).first 
a = i.account

# el numero de factura lleva anexionado el ID del cliente.
invoice_number = "#{a.id.to_guid}.#{i.id.to_guid}"
subscr_id = 'I-U1VUKAX36LNE'

# fake IPN regarding a new subscription
h = {
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

# save the IPN
ipn = BlackStack::I2P::BufferPayPalNotification.new(h)
ipn.save

# process the IPN
ipn.process