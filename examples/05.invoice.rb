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
  :fee=>5, # this is the fee that your will charge to the client, as a special offer price.
  :period=>1,
  :units=>"M", # billed monthy
}])

# Create the invoice 
i = BlackStack::I2P::Invoice.new()
i.id = guid
i.id_account = BlackStack::MySaaS::Account.first.id
i.create_time = now
i.disabled_trial = false
i.save

# Add a plan as an invoice item
i.add_item('leads.starter')
