# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/i2p'

BlackStack::I2P::set_plans([
# Dedicated Support - 
{
  # which product is this plan belonging
  :product_code=>'dedicated-support', 
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
  :fee=>29, # this is the fee that your will charge to the client, as a special offer price.
  :period=>1,
  :units=>"M", # billed monthy
}, {
  # which product is this plan belonging
  :product_code=>'dedicated-support', 
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
  :fee=>79, # this is the fee that your will charge to the client, as a special offer price.
  :period=>1,
  :units=>"M", # billed monthy
}])

puts BlackStack::I2P::plans_descriptor
# => [{...}, {...}] 
