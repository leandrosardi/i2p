require_relative '../lib/i2p'

BlackStack::I2P::set_paypal_business_email(
  "sardi.leandro.daniel.x@gmail.com"  
)

puts BlackStack::I2P::paypal_business_email
# => "sardi.leandro.daniel.x@gmail.com" 
