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

BlackStack::I2P::set_services([
{ 
  :code=>'dedicated-support', 
  :name=>'Dedicated Support', 
  :unit_name=>'support agents', 
  :consumption=>BlackStack::I2P::CONSUMPTION_BY_TIME, 
  :description=>'Dedicated Support, Consultancy & Campaigns Management.',
  :summary=>'Get One Account Manager for Your Campaigns.',
  :thumbnail=>'https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png',
  :return_path=>'https://yourwebsite.com/dedicated-support/welcome',
},
{ 
  :code=>'2020-event-ticket', 
  :name=>'Ticket to the BlackStack eCommerce Summit 2020', 
  :unit_name=>'tickets', 
  :consumption=>BlackStack::I2P::CONSUMPTION_BY_UNIT, 
  :description=>'Ticket to the BlackStack eCommerce Summit 2020. Live Streaming of all the Converences.', 
  :summary=>'The BlackStack eCommerce Summit is the larger event about building aggressive and cost effective marketing strategies using the BlackStack framework and many other resources.',
  :thumbnail=>'https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png',
  :return_path=>'https://yourwebsite.com/event2020/step1',
}])

puts BlackStack::I2P::services_descriptor
# => [{...}, {...}] 
