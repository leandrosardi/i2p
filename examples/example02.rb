require_relative '../lib/invoicing_payments_processing'

BlackStack::InvoicingPaymentsProcessing::set_paypal_business_email(
  "sardi.leandro.daniel.x@gmail.com"  
)

puts BlackStack::InvoicingPaymentsProcessing::paypal_business_email
# => "sardi.leandro.daniel.x@gmail.com" 
