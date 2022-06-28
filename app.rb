# screens
get '/extensions/leads/views/subscriptions', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/leads/views/subscriptions', :layout => :'/views/layouts/core'
end
  
get '/extensions/leads/views/invoices', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/leads/views/invoices', :layout => :'/views/layouts/core'
end
  
get '/extensions/leads/views/invoice', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/leads/views/invoice', :layout => :'/views/layouts/core'
end
    
get '/extensions/leads/views/transactions', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/leads/views/transactions', :layout => :'/views/layouts/core'
end
  

# filters
get '/extensions/leads/views/filter_create_invoice', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/leads/views/filter_create_invoice'
end
  
get '/extensions/leads/views/filter_add_invoice_item', :agent => /(.*)/ do
    erb :'/extensions/leads/views/filter_add_invoice_item'
end
  
get '/extensions/leads/views/filter_remove_invoice_item', :agent => /(.*)/ do
    erb :'/extensions/leads/views/filter_remove_invoice_item'
end
  
get '/extensions/leads/views/filter_goto_invoice_paypal', :agent => /(.*)/ do
    erb :'/extensions/leads/views/filter_goto_invoice_paypal'
end
  
get '/extensions/leads/views/filter_update_subscription', :agent => /(.*)/ do
    erb :'/extensions/leads/views/filter_update_subscription'
end

# API (pending)
# TODO: code API access points