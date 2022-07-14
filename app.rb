# screens
get '/settings/subscriptions', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/subscriptions', :layout => :'/views/layouts/core'
end
  
get '/settings/invoices', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/invoices', :layout => :'/views/layouts/core'
end
  
get '/settings/invoice', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/invoice', :layout => :'/views/layouts/core'
end
    
get '/settings/transactions', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/transactions', :layout => :'/views/layouts/core'
end
  

# filters
get '/settings/filter_create_invoice', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_create_invoice'
end
  
get '/settings/filter_delete_invoice', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_delete_invoice'
end

get '/settings/filter_add_invoice_item', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_add_invoice_item'
end
  
get '/settings/filter_remove_invoice_item', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_remove_invoice_item'
end
  
get '/settings/filter_goto_invoice_paypal', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_goto_invoice_paypal'
end
  
get '/settings/filter_update_subscription', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/filter_update_subscription'
end

# AJAX
post '/ajax/i2p/get_credits.json', :auth => true, :agent => /(.*)/ do
    erb :'/extensions/i2p/views/ajax/get_credits'
end

# API
get '/api1.0/i2p/ipn.json', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/api1.0/ipn'
end
post '/api1.0/i2p/ipn.json', :agent => /(.*)/ do
    erb :'/extensions/i2p/views/api1.0/ipn'
end