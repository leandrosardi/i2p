require_relative '../lib/i2p'
require_relative './conf'

puts BlackStack::InvoicingPaymentsProcessing::paypal_ipn_listener
# => http://blackstack.io:80/api1.3/accounting/paypal/notify_new_invoice.json