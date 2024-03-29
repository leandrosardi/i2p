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

BlackStack::I2P::set_plans([
# Dedicated Support - 
{
  # which product is this plan belonging
  :service_code=>'dedicated-support', 
  # recurrent billing plan or one-time payments
  :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
  # show this plan in the UI
  :public=>true,
  # is this a One-Time Offer?
  # true: this plan is available only if the account has not any invoice using this plan
  # false: this plan can be purchased many times
  :one_time_offer=>false,  
  # plan description
  :item_number=>"dedicated-support.developer", 
  :name=>"Dedicated Support - Starter Plan", 
  # billing details
  :credits=>1, # only 1 support agent
  :normal_fee=>299, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
  :fee=>29, # this is the fee that your will charge to the account, as a special offer price.
  :period=>'month',
  :units=>1, # billed monthy
}, {
  # which product is this plan belonging
  :service_code=>'dedicated-support', 
  # recurrent billing plan or one-time payments
  :type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
  # show this plan in the UI
  :public=>true,
  # is this a One-Time Offer?
  # true: this plan is available only if the account has not any invoice using this plan
  # false: this plan can be purchased many times
  :one_time_offer=>false,  
  # plan description
  :item_number=>"dedicated-support.business", 
  :name=>"Dedicated Support - Starter Plan", 
  # billing details
  :credits=>1, # only 1 support agent
  :normal_fee=>899, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
  :fee=>79, # this is the fee that your will charge to the account, as a special offer price.
  :period=>'month',
  :units=>1, # billed monthy
}])

puts BlackStack::I2P::plans_descriptor
# => [{...}, {...}] 
