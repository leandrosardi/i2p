require_relative '../lib/i2p'
require_relative './conf'

# We'll create and simulate payments to an invoice with this ID
# 
id_invoice = '71173f0f-5f2d-4b29-8a64-d002c3be8f23'

# Choose division to connect
# 
BlackStack::Pampa::set_division_name(
  'copernico'
)

# Connect to database
# 
DB = BlackStack::Pampa::db_connection

# Setup Sequel database classes
#
BlackStack::Pampa::require_db_classes
BlackStack::InvoicingPaymentsProcessing::require_db_classes

# Load client 
#
c = BlackStack::Client.where(:api_key=>BlackStack::Pampa::api_key).first

# Create the invoice 
#
i = BlackStack::Invoice.new()
i.id = id_invoice
i.id_client = c.id
i.create_time = now()
i.disabled_for_trial = c.disabled_for_trial
i.save()  

# Add a plan as an invoice item
#
i.add_item('THR.Unique-Plan')
i.add_item('STO.Small-Plan')
