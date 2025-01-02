# update the consumption of the day

# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/main'

b = BlackStack::I2P::Account.where(:id=>'c976aa79-090e-459d-b8e1-4fba8ea4f770').first
d = Time.new(2023,7,27,0,0,0)
b.update_consumption_of_the_day('leads', d)
