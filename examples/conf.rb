# -----------------------------------------------------------------------------------------------------
# servicio web de la base de datos central - keep it secret
# -----------------------------------------------------------------------------------------------------
# setup connection to the database
BlackStack::Pampa::set_api_url({
  # IMPORTANT: It is strongly recommended that you 
  # use the api_key of an account with prisma role, 
  # and assigned to the central division too.
  :api_key => 'E20CBAE0-A4D4-4161-8812-6D9FE67A2E47',
  # IMPORTANT: It is stringly recommended that you 
  # write the URL of the central division here. 
  :api_protocol => 'https',
  :api_domain => '127.0.0.1',
  :api_port => 443,
})

# -----------------------------------------------------------------------------------------------------
# db access to the central - keep it secret
# -----------------------------------------------------------------------------------------------------
BlackStack::Pampa::set_db_params({
  :db_url => 'Leandro1\\DEV',
  :db_port => 1433,
  :db_name => 'kepler',
  :db_user => '',
  :db_password => '',  
})

# -----------------------------------------------------------------------------------------------------
# Setup products
# -----------------------------------------------------------------------------------------------------
BlackStack::I2P::set_products([
  { 
    :code=>'thr', 
    :icon => "program.ssm.png", 
    :name=>"Processing Threads", 
    :unit_name=>"threads", 
    :consumption=>BlackStack::I2P::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::I2P::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Dedicated Processing Threads for Bots.",
    :summary=>"Get many processing threads working in paralell in order to scale your bot farm.",
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"/threads/dashbaord",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>'sto', 
    :icon => "program.ssm.png", 
    :name=>"Account Storage", 
    :unit_name=>"MBs", 
    :consumption=>BlackStack::I2P::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::I2P::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"512MB Storage in your Account.",
    :summary=>"Disk Space for Browser Profiles, Logs, Pictures, Reports.",
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"/",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
])

# -----------------------------------------------------------------------------------------------------
# Setup plans
# -----------------------------------------------------------------------------------------------------
BlackStack::I2P::set_plans([

  # Threads
  {
    :type=>BlackStack::I2P::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>'thr', 
    :item_number=>"THR.Unique-Plan", 
    :name=>"Hosted Processing Threads", 
    :credits=>1, 
    :normal_fee=>29.99, 
    :fee=>9.99, 
    :period=>1, 
    :units=>"M", 
    :upsells=>[],
    :bonus_plans=>[],
  },

  # Storage
  {
    :type=>BlackStack::I2P::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>'sto', 
    :item_number=>"STO.Small-Plan", 
    :name=>"Storage MBs", 
    :credits=>512, 
    :normal_fee=>19.99, 
    :fee=>9.99, 
    :period=>1, 
    :units=>"M", 
    :upsells=>[],
    :bonus_plans=>[],
  },
])
