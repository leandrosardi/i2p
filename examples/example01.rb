require_relative '../lib/invoicing_payments_processing'
require_relative './conf'

puts BlackStack::InvoicingPaymentsProcessing::paypal_ipn_listener
# => http://blackstack.io:80/api1.3/accounting/paypal/notify_new_invoice.json