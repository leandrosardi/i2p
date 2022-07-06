# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/i2p'

# define your product
BlackStack::I2P::set_products([
  { 
    :code=>'leads', 
    :name=>'B2B Contacts', 
    :unit_name=>'records', 
    :consumption=>BlackStack::I2P::CONSUMPTION_BY_TIME, 
    # what is the life time of this product or service?
    :credits_expiration_period => 'month',
    :credits_expiration_units => 1,
    # 
    :description=>'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
    :summary=>'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
    :thumbnail=>'https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png',
    :return_path=>'https://yourwebsite.com/dedicated-support/welcome',
  },
])

# define a plan for your product
BlackStack::I2P::set_plans([
# Dedicated Support - 
{
  # which product is this plan belonging
  :product_code=>'leads', 
  # recurrent billing plan or one-time payments
  :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
  # show this plan in the UI
  :public=>true,
  # is this a One-Time Offer?
  # true: this plan is available only if the account has not any invoice using this plan
  # false: this plan can be purchased many times
  :one_time_offer=>false,  
  # plan description
  :item_number=>"leads.starter", 
  :name=>"Leads - Starter Plan", 
  # billing details
  :credits=>50, # only 1 support agent
  :normal_fee=>17, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
  :fee=>5, # this is the fee that your will charge to the account, as a special offer price.
  :period=>'month',
  :units=>1, # billed monthy
}])

# find the latest created invoice, and its associated account
i = BlackStack::I2P::Invoice.order(:create_time).last 
a = i.account

# el numero de factura lleva anexionado el ID del cliente.
invoice_number = "#{a.id.to_guid}.#{i.id.to_guid}"
subscr_id = 'I-U1VUKAX36LNE'

# fake IPN regarding the payment of the new subscrion in the previous example
h = {
  "create_time" => '20191224150000', 
  "transaction_subject"=>"Leads - Starter Plan", 
  "payment_date"=>"08:42:17 Oct 26, 2018 PDT", 
  "txn_type"=>"subscr_payment", 
  "subscr_id"=>subscr_id, 
  "last_name"=>"buyer", 
  "residence_country"=>"US", 
  "item_name"=>"Leads - Starter Plan", 
  "payment_gross"=>"5.00", 
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
  "item_number"=>"leads.starter", 
  "payment_status"=>"Completed", 
  "payment_fee"=>"0.59", 
  "mc_fee"=>"0.59", 
  "mc_gross"=>"5.00", 
  "charset"=>"windows-1252", 
  "notify_version"=>"3.9", 
  "ipn_track_id"=>"43b9a672808ba"
}

# save the IPN
ipn = BlackStack::I2P::BufferPayPalNotification.new(h)
ipn.save

# process the IPN
ipn.process
