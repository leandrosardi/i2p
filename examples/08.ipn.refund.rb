# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/main'

# Setup configuration
BlackStack::I2P::set({
    'paypal_business_email' => 'sardi.leandro.daniel@gmail.com',
    'paypal_ipn_listener' => "#{CS_HOME_WEBSITE}/api1.0/i2p/paypal/ipn.json",
})

# setup the product
BlackStack::I2P::add_services([
    { 
        :code=>'leads', 
        :name=>'B2B Contacts', 
        :unit_name=>'records', 
        :consumption=>BlackStack::I2P::CONSUMPTION_BY_TIME, 
        # formal description to show in the list of products
        :description=>'B2B Contacts with Emails & Phone Numbers',
        # persuasive description to show in the sales letter
        :title=>'The Best Data Quality, at the Best Price',
        # larger persuasive description to show in the sales letter
        :summary=>'B2B Contacts with verified <b>email addresses</b>, <b>phone numbers</b> and <b>LinkedIn profiles</b>.',
        :thumbnail=>"#{CS_HOME_WEBSITE}/leads/images/logo.png",
        :return_path=>"#{CS_HOME_WEBSITE}/leads/results",
        # what is the life time of this product or service?
        :credits_expiration_period => 'month',
        :credits_expiration_units => 1,
        # free tier configuration
        :free_tier=>{
            # add 10 records per month, for free
            :credits=>10,
            :period=>'month',
            :units=>1,
        },
        # most popular plan configuratioon
        :most_popular_plan => 'leads.batman',
    },
])

# setup the plan
BlackStack::I2P::add_plans([
    {
        # which product is this plan belonging
        :service_code=>'leads', 
        # recurrent billing plan or one-time payments
        :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
        # show this plan in the UI
        :public=>true,
        # is this a One-Time Offer?
        # true: this plan is available only if the account has not any invoice using this plan
        # false: this plan can be purchased many times
        :one_time_offer=>false,  
        # plan description
        :item_number=>'leads.robin', 
        :name=>'Robin', 
        # billing details
        :credits=>28, 
        :normal_fee=>7, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
        :fee=>7, # this is the fee that your will charge to the account, as a special offer price.
        :period=>'month',
        :units=>1, # billed monthy
    }, {
        # which product is this plan belonging
        :service_code=>'leads', 
        # recurrent billing plan or one-time payments
        :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
        # show this plan in the UI
        :public=>true,
        # is this a One-Time Offer?
        # true: this plan is available only if the account has not any invoice using this plan
        # false: this plan can be purchased many times
        :one_time_offer=>false,  
        # plan description
        :item_number=>'leads.batman', 
        :name=>'Batman', 
        # billing details
        :credits=>135, 
        :normal_fee=>33, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
        :fee=>27, # this is the fee that your will charge to the account, as a special offer price.
        :period=>'month',
        :units=>1, # billed monthy
    }, {
        # which product is this plan belonging
        :service_code=>'leads', 
        # recurrent billing plan or one-time payments
        :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
        # show this plan in the UI
        :public=>true,
        # is this a One-Time Offer?
        # true: this plan is available only if the account has not any invoice using this plan
        # false: this plan can be purchased many times
        :one_time_offer=>false,  
        # plan description
        :item_number=>'leads.hulk', 
        :name=>'Hulk', 
        # billing details
        :credits=>314, 
        :normal_fee=>79, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
        :fee=>47, # this is the fee that your will charge to the account, as a special offer price.
        :period=>'month',
        :units=>1, # billed monthy
    }
])

# find the latest created invoice, and its associated account
i = BlackStack::I2P::Invoice.order(:create_time).first 
a = i.account

# el numero de factura lleva anexionado el ID del cliente.
invoice_number = "#{a.id.to_guid}.#{i.id.to_guid}"
subscr_id = 'I-U1VUKAX36LNE'

# fake IPN regarding the payment of the new subscrion in the previous example
h = {
  "create_time" => '20191224150000', 
  "transaction_subject"=>"Leads - Starter Plan", 
  "payment_date"=>"08:42:17 Oct 26, 2018 PDT", 
  "txn_type"=>"", 
  "subscr_id"=>subscr_id, 
  "last_name"=>"buyer", 
  "residence_country"=>"US", 
  "item_name"=>"Leads - Starter Plan", 
  "payment_gross"=>"-47.00", 
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
  "payment_status"=>"Refunded", 
  "payment_fee"=>"0.59", 
  "mc_fee"=>"-0.59", 
  "mc_gross"=>"-47.00", 
  "charset"=>"windows-1252", 
  "notify_version"=>"3.9", 
  "ipn_track_id"=>"43b9a672808ba"
}

# save the IPN
ipn = BlackStack::I2P::BufferPayPalNotification.new(h)
ipn.save

# process the IPN
ipn.process