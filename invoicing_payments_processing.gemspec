Gem::Specification.new do |s|
  s.name        = 'invoicing_payments_processing'
  s.version     = '1.1.82'
  s.date        = '2022-05-03'
  s.summary     = "THIS GEM IS STILL IN DEVELOPMENT STAGE. Invoicing and Payments Processing gem (a.k.a. I+2P) is a Ruby gem to setup amazing offers in your website, track them, and also process payments automatically using PayPal."
  s.description = "THIS GEM IS STILL IN DEVELOPMENT STAGE. Find documentation here: https://github.com/leandrosardi/invoicing_payments_processing."
  s.authors     = ["Leandro Daniel Sardi"]
  s.email       = 'leandro.sardi@expandedventure.com'
  s.files       = [
    'lib/invoicing_payments_processing.rb',
    'lib/balance.rb',
    'lib/bufferpaypalnotification.rb',
    'lib/customplan.rb',
    'lib/invoice.rb',
    'lib/invoiceitem.rb',
    'lib/movement.rb',
    'lib/paypalsubscription.rb',
    'lib/extend_client_by_invoicing_payments_processing.rb'
  ]
  s.homepage    = 'https://rubygems.org/gems/invoicing_payments_processing'
  s.license     = 'MIT'
  s.add_runtime_dependency 'websocket', '~> 1.2.8', '>= 1.2.8'
  s.add_runtime_dependency 'json', '~> 1.8.1', '>= 1.8.1'
  s.add_runtime_dependency 'tiny_tds', '~> 1.0.5', '>= 1.0.5'
  s.add_runtime_dependency 'sequel', '~> 4.28.0', '>= 4.28.0'
  s.add_runtime_dependency 'pampa_workers', '~> 1.1.24', '>= 1.1.24'
end