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

puts BlackStack::I2P::paypal_ipn_listener
# => http://192.168.0.11:80/api1.0/i2p/paypal/ipn.json
