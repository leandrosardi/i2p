require_relative '../lib/i2p'

BlackStack::I2P::set_plans([
# Dedicated Support - 
{
  # recurrent billing plan
  :type=>BlackStack::I2P::BasePlan::PAYMENT_SUBSCRIPTION,  
  
  :public=>true,
  
  # true: this plan is available only if the client has not any other invoice including this plan
  # false: this plan can be purchased many times
  :one_time_offer=>false,  
  
  # which product is this plan belong
  :product_code=>'dedicated-support', 
  
  # plan description
  :item_number=>"deducated-support.starter-plan", 
  :name=>"Dedicated Support - Starter Plan", 
  
  # billing details
  :credits=>1, # only 1 support agent
  :normal_fee=>299, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
  :fee=>99, # this is the fee that your will charge to the client, as a special offer price.
  :period=>1,
  :units=>"M", # billed monthy
},
{
  # recurrent billing plan
  :type=>BlackStack::I2P::BasePlan::PAYMENT_SUBSCRIPTION,  
  
  :public=>true,
  
  # true: this plan is available only if the client has not any other invoice including this plan
  # false: this plan can be purchased many times
  :one_time_offer=>false,  
  
  # which product is this plan belong
  :product_code=>'dedicated-support', 
  
  # plan description
  :item_number=>"deducated-support.enterprise-plan", 
  :name=>"Dedicated Support - Enterprise Plan", 
  
  # billing details
  :credits=>2, # Oh! 2 support agents!!
  :normal_fee=>499, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
  :fee=>199, # this is the fee that your will charge to the client, as a special offer price.
  :period=>1,
  :units=>"M", # billed monthy
}])

puts BlackStack::I2P::plans_descriptor
# => [{...}, {...}] 
