# manually pay an invoice

# load gem and connect database
require 'mysaas'
require 'lib/stubs'
require 'config'
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'
require 'extensions/i2p/lib/skeletons'
require 'extensions/i2p/main'

i = BlackStack::I2P::Invoice.where(:id=>'53093b82-bd90-45cf-94b8-773bee6111e4').first

dt = now()

i.getPaid(dt)

j = BlackStack::I2P::Invoice.new()
j.id = guid()
j.id_account = i.id_account
j.create_time = dt
j.disabled_trial = i.account.disabled_trial
j.save()

# genero los datos de esta factura, como la siguiente factura a la que estoy pagando en este momento
j.next(i)
