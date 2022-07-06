# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/i2p'

BlackStack::I2P::set_products([
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

puts BlackStack::I2P::products_descriptor
# => [{...}, {...}] 
