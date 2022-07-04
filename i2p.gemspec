Gem::Specification.new do |s|
  s.name        = 'i2p'
  s.version     = '1.2.1'
  s.date        = '2022-06-28'
  s.summary     = "Invoicing and Payments Processing gem (a.k.a. I+2P) is a Ruby gem to setup amazing offers in your website, track them, and also process payments automatically using PayPal."
  s.description = "Find documentation here: https://github.com/leandrosardi/i2p."
  s.authors     = ["Leandro Daniel Sardi"]
  s.email       = 'leandro.sardi@expandedventure.com'
  s.files       = [
    'lib/i2p.rb',
    'lib/balance.rb',
    'lib/bufferpaypalnotification.rb',
    'lib/customplan.rb',
    'lib/invoice.rb',
    'lib/invoiceitem.rb',
    'lib/movement.rb',
    'lib/subscription.rb',
    'lib/extend_client_by_i2p.rb'
  ]
  s.homepage    = 'https://rubygems.org/gems/i2p'
  s.license     = 'MIT'
  s.add_runtime_dependency 'websocket', '~> 1.2.8', '>= 1.2.8'
  s.add_runtime_dependency 'json', '~> 1.8.1', '>= 1.8.1'
  s.add_runtime_dependency 'tiny_tds', '~> 1.0.5', '>= 1.0.5'
  s.add_runtime_dependency 'sequel', '~> 4.28.0', '>= 4.28.0'
  s.add_runtime_dependency 'pampa_workers', '~> 1.1.24', '>= 1.1.24'
end