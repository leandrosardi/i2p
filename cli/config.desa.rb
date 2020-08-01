# 
DEFAULT_WORKER_NAME = 'unicorn01'

# 
DEFAULT_DIVISION_NAME = 'copernico'

# -----------------------------------------------------------------------------------------------------
# portal del servicio de ConnectionSphere
# -----------------------------------------------------------------------------------------------------
CS_HOME_PAGE_PROTOCOL = "https"
CS_HOME_PAGE_DOMAIN = "connectionsphere.com"
CS_HOME_PAGE_PORT = "443"
CS_HOME_WEBSITE = "#{CS_HOME_PAGE_PROTOCOL}://#{CS_HOME_PAGE_DOMAIN}:#{CS_HOME_PAGE_PORT}"

# -----------------------------------------------------------------------------------------------------
# servicio web de la base de datos central - keep it secret
# -----------------------------------------------------------------------------------------------------
# setup connection to the database
BlackStack::Pampa::set_api_url({
  # IMPORTANT: It is strongly recommended that you 
  # use the api_key of an account with prisma role, 
  # and assigned to the central division too.
  :api_key => '6F450B22-CFBB-424D-A6C1-F249F4912F40',
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

#
# List of product codes
#
PRODUCT_SUP = 'sup' # dedicated support
PRODUCT_SSM = 'ssm' # warm leads
PRODUCT_THR = 'thr' # processing threads
#PRODUCT_SRV = 'srv' # dedicated servers
#PRODUCT_SBR = 'sbr' # stealth browser
PRODUCT_STO = 'sto' # account storage
PRODUCT_SCL = 'scl' # cloud logging
PRODUCT_SHM = 'shm' # host monitorors
PRODUCT_DRX = 'drx' # invitations (for LinkedIn Prospector)
PRODUCT_AUT = 'aut' # automation rules
PRODUCT_EDB = 'edb' # searches (for LinkedIn Scraping)
PRODUCT_MAC = 'mac' # bots (for LinkedIn Creator, Scraping & Prospector)
PRODUCT_PVA = 'pva' # accounts
PRODUCT_IP6 = 'ip6' # proxies
PRODUCT_ACC = 'acc' # social account rental. includes proxy.
PRODUCT_FLD = 'fld' # record
PRODUCT_EF = 'ef' # email address
#PRODUCT_IPJ = 'ipj' # members
#PRODUCT_IP4 = 'ip4' # proxies
#PRODUCT_IPM = 'ipm' # proxies
#PRODUCT_EDU = 'edu' # book

# -----------------------------------------------------------------------------------------------------
# Setup products
# -----------------------------------------------------------------------------------------------------
#
# Descriptor of list of products
#
BlackStack::InvoicingPaymentsProcessing::set_products([
  { 
    :code=>PRODUCT_SUP, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Dedicated Support", 
    :unit_name=>"agent", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_AGENCY,
    :description=>"Dedicated Support, Optimization & Campaigns Management.",
    :summary=>"Get One Account Manager for Your Campaigns.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/main/dashboard",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me!
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M", 
  },
  { 
    :code=>PRODUCT_SSM, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"SocialSellingMachine", 
    :unit_name=>"warm leads", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_AGENCY,
    :description=>"SocialSellingMachine Program", 
    :summary=>"Receive emails of people interested in what you offer.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1?program=ssm",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>3, 
    :credits_expiration_period=>"M",  
		# Create bonus automatically to compensate negativa balance.
		:give_away_negative_credits => true, # default true
  },
  { 
    :code=>PRODUCT_THR, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Processing Threads", 
    :unit_name=>"threads", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Additional Processing Threads for your Automation.",
    :summary=>"Get many processing threads working in paralell in order to scale your campaign.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/thr/dashboard?program=thr",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
=begin
  { 
    :code=>PRODUCT_SRV, 
    :name=>"Dedicated Servers", 
    :unit_name=>"servers", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Dedicated Server for Isolated Fingerprinting.",
    :summary=>"You can assign a limited number of accounts to each dedicated server, so you can control the stealth of your whole farm.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/thr/dashbaord",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
  },
  { 
    :code=>PRODUCT_SBR, 
    :name=>"Stealth Browser Profiles", 
    :unit_name=>"profiles", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Stealth Browser Profiles with Counter-Fingerprinting Technology Included.",
    :summary=>"Each Stealth Browser Profile will spoof both: software and hardward fingerprints. It's good to launch as many accounts as you want in one single thread.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/thr/dashbaord",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
  },
=end
  { 
    :code=>PRODUCT_STO, 
    :public=>false,
    :icon => "program.ssm.png", 
    :name=>"Account Storage", 
    :unit_name=>"MBs", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"512MB Storage in your Account.",
    :summary=>"Disk Space for Browser Profiles, Logs, Pictures, Reports.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/main/dashboard",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_SCL, 
    :public=>false,
    :icon => "program.ssm.png", 
    :name=>"Cloud Logging", 
    :unit_name=>"logfiles", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"Save and analyze your logs in the cloud.",
    :summary=>"Save and analyze your logs in the cloud. Publish your logs in any website.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/main/dashboard",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_SHM, 
    :public=>false,
    :icon => "program.ssm.png", 
    :name=>"Host Monitoring", 
    :unit_name=>"hosts", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"Real-time monitor of CPU, RAM and disk space.",
    :summary=>"Setup threashold alerts and get email notifications before your servers break down.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/shm/dashboard?program=shm",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_DRX, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Linked Prospector", 
    :unit_name=>"invitations", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"Generate Sales on LinkedIn through automated prospecting.",
    :summary=>"Unlimited accounts allowed. Setup automated invitations & messages follow-ups. Manage one unique conversation with every lead. Manage the chat of thousands of accounts from one single dashboard. Proprietary browser with counter-fingerprinting technology.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1?program=drx",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_AUT, 
    :public=>false,
    :icon => "program.ssm.png", 
    :name=>"Automation", 
    :unit_name=>"rules", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"Move leads between pipelines.",
    :summary=>"Move leads between pipelines, in order to do a high customized campaign.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1?program=aut",
    :landing_page=>"http://ConnectionSphere.com/automation", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_EDB, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Linked Scraper", 
    :unit_name=>"searches", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"Replacate and Scrape Sales Navigator Searches.",
    :summary=>"Scrape 90% of any LinkedIn search, even if the search is larger than 10,000 results.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/edb/searches?program=edb",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_MAC, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Linked Creator", 
    :unit_name=>"accounts", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
    :description=>"More Slots to Upload Your Own Accounts.",
    :summary=>"Automated Signup, Email Confirmation, Profile Edition. SMS Verifictions. Captcha Resolving. One Stealth Browser Profiles for each Account with Counter-Fingerprinting Technology.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/mac/dashboard?program=mac",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_PVA, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Phone Verified Accounts", 
    :unit_name=>"pva credits", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"LinkedIn Accounts for Sale.",
    :summary=>"Every account is worth $1 or more depending upon how old is it and how many connections it already has. Don't include proxies.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/pva/results?program=pva",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"Y",  
  },
  { 
    :code=>PRODUCT_IP6, 
    :public=>false,
    :icon => "program.ssm.png", 
    :name=>"IPv6 Proxies", 
    :unit_name=>"proxies", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Mass Bulk Fresh IPv6 Proxies.",
    :summary=>"Mass warehouse of IPv6 proxies for social accounts.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/prx/dashboard",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_ACC, 
    :public=>true,
    :icon => "program.ssm.png", 
    :name=>"Social Accounts for Rent", 
    :unit_name=>"accounts", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
    :description=>"Social Accounts Rental. Include Proxies.",
    :summary=>"Social accounts rental. Include proxies. You can't login the accounts yourself. But you can handle them through our platform and watch their activity.",
    :thumbnail=>"#{CS_HOME_WEBSITE}/assets/images/modules.png",
    :return_path=>"#{CS_HOME_WEBSITE}/mac/lnusers?program=mac",
    :landing_page=>"http://SocialSellingMachine.com", # TODO: edit me! 
    :credits_expiration_units=>1, 
    :credits_expiration_period=>"M",  
  },
  { 
    :code=>PRODUCT_EF, 
    :public=>false,
    :name=>"Email Forwarding", 
    :unit_name=>"email addresses", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
  },
=begin
  { 
    :code=>PRODUCT_FLD, 
    :name=>"FreeLeadsData", 
    :unit_name=>"records", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_SOFTWARE,
  },
  { 
    :code=>PRODUCT_IPJ, 
    :name=>"InvitePeopleToJoin", 
    :unit_name=>"members", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_AGENCY,
  },
  { 
    :code=>PRODUCT_IP4, 
    :name=>"IPv4 Proxies", 
    :unit_name=>"proxies", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
  },
  { 
    :code=>PRODUCT_IPM, 
    :name=>"Mobile Proxies", 
    :unit_name=>"proxies", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_UNIT, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_WAREHOUSE,
  },
  { 
    :code=>PRODUCT_EDU, 
    :name=>"BlackStack Seminars", 
    :unit_name=>"seminar", 
    :consumption=>BlackStack::InvoicingPaymentsProcessing::BasePlan::CONSUMPTION_BY_TIME, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PRODUCT_EDUCATION,
  },
=end
])

BlackStack::InvoicingPaymentsProcessing::set_plans([
=begin
  # Programas de Educacion
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO,
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_EDU, 
    :item_number=>"EDU.B2B-Selling-Mastery", 
    :name=>"B2B Selling Mastery", 
    :credits=>1, 
    :normal_fee=>99, 
    :fee=>29, 
    :units=>1, 
    :period=>"M", 
    :description=>"BlackStack Seminars - B2B Selling Mastery.", 
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1",
  },
  
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_EDU, 
    :item_number=>"EDU.B2B-Selling-Fraternity", 
    :name=>"B2B Selling Fraternity", 
    :credits=>1, 
    :normal_fee=>27, 
    :fee=>7, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :description=>"B2B Selling Fraternity",
    :summary=>"More than 5,000 marketers sharing experiences and testing results.",
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1",
  },
=end

  # Dedicated Support
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SUP, 
    :item_number=>"SUP.Dedicated-Support", 
    :name=>"Dedicated Support", 
    :credits=>1, 
    :normal_fee=>299, 
    :fee=>149, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },


# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------
# START > Published plans in the landing page of the SocialSellingMachine.com 
# 
  # LinkedIn Prospector
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_DRX, 
    :item_number=>"SSM.1.SaaS", 
    :name=>"SaaS", 
    :credits=>2500, 
    :normal_fee=>149, 
    :fee=>49, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>2000, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :upsells=>["PVA.Plan-10", "MAC.Plan-20", "SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "MAC.Plan-20", :period => 1 },
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 0, # default 0
  },

  # Programa SSM - Planes Mensuales
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true, # used in the landing page
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.2.Semi-Dedicated-Monthly", 
    :name=>"Semi-Dedicated", 
    :credits=>25, 
    :fee=>99, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :upsells=>["ACC.Plan-20", "SUP.Dedicated-Support", "THR.Unique-Plan"],
    :bonus_plans=>[
      { :item_number => "MAC.Plan-20", :period => 1 },
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
  
  # Programa SSM - Planes Mensuales
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true, # used in the landing page
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.3.Full-Dedicated-Monthly", 
    :name=>"Agency", 
    :credits=>25, 
    :fee=>249, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :upsells=>["ACC.Plan-20", "THR.Unique-Plan", "MAC.Plan-20"],
    :bonus_plans=>[
      { :item_number => "MAC.Plan-20", :period => 1 },
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "SUP.Dedicated-Support", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
# 
# END > Published plans in the landing page of the SocialSellingMachine.com 
# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------

  # Programa SSM - Planes Mensuales
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Robin-Monthly", 
    :name=>"SSM Robin Plan", 
    :credits=>25, 
    :fee=>99, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["SSM.Batman-Monthly", "SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Batman-Monthly", 
    :name=>"SSM Batman Plan", 
    :credits=>65, 
    :normal_fee=>257, 
    :fee=>249, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["SSM.Hulk-Monthly", "SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 2 }, 
      { :item_number => "STO.Medium-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 3 },
      { :item_number => "DRX.Plan-8000", :period => 1 },
      { :item_number => "EDB.Plan-15", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
      { :item_number => "SUP.Dedicated-Support", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  }, 
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Hulk-Monthly", 
    :name=>"SSM Hulk Plan", 
    :credits=>140, 
    :normal_fee=>555, 
    :fee=>499, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 3 }, 
      { :item_number => "STO.Large-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 6 },
      { :item_number => "DRX.Plan-16000", :period => 1 },
      { :item_number => "EDB.Plan-50", :period => 1 },
      { :item_number => "MAC.Plan-45", :period => 1 },
      { :item_number => "SUP.Dedicated-Support", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  }, 

  # Programa SSM - Abonos Fijos por Unica Vez
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Small-Pay-As-You-Go", 
    :name=>"SSM Small Pay-As-You-Go", 
    :credits=>10, 
    :fee=>50, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Robin-Pay-As-You-Go", 
    :name=>"SSM Robin Pay-As-You-Go", 
    :credits=>20, 
    :fee=>99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Batman-Pay-As-You-Go", 
    :name=>"SSM Batman Pay-As-You-Go", 
    :credits=>55, 
    :fee=>249, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 2 }, 
      { :item_number => "STO.Medium-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 3 },
      { :item_number => "DRX.Plan-8000", :period => 1 },
      { :item_number => "EDB.Plan-15", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
      { :item_number => "SUP.Dedicated-Support", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  }, 
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM, 
    :item_number=>"SSM.Hulk-Pay-As-You-Go", 
    :name=>"SSM Hulk Pay-As-You-Go", 
    :credits=>120, 
    :fee=>499, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 3 }, 
      { :item_number => "STO.Large-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 6 },
      { :item_number => "DRX.Plan-16000", :period => 1 },
      { :item_number => "EDB.Plan-50", :period => 1 },
      { :item_number => "MAC.Plan-45", :period => 1 },
      { :item_number => "SUP.Dedicated-Support", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  }, 

  # Programa SSM - Ofertas - Flash Sales - Tripwires
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION,
    :public=>false,
    :one_time_offer=>true, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SSM,
    :item_number=>"SSM.Robin-Montly-50%-Off-First-Month", 
    :name=>"SSM Robin 50% Off", 
    :credits=>25, :fee=>99, 
		:units=>1, 
		:period=>"M", 
    :trial_credits=>10, :trial_fee=>1, :trial_units=>15, :trial_period=>"D",
    :trial2_credits=>25, :trial2_fee=>50, :trial2_units=>1, :trial2_period=>"M",
    #:upsells=>["SUP.Dedicated-Support"],
    :bonus_plans=>[
      { :item_number => "THR.Unique-Plan", :period => 1 }, 
      { :item_number => "STO.Small-Plan", :period => 1 },
      { :item_number => "ACC.Plan-20", :period => 1 },
      { :item_number => "DRX.Plan-4000", :period => 1 },
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 3, # default 0
  },
  
  # Threads
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_THR, 
    :item_number=>"THR.Unique-Plan", 
    :name=>"Hosted Processing Threads", 
    :credits=>1, 
    :normal_fee=>29.99, 
    :fee=>9.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>[],
    #:bonus_plans=>[],
    # Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
=begin
  # Dedicated Servers
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SRV, 
    :item_number=>"SRV.Unique-Plan", 
    :name=>"Dedicated Servers", 
    :credits=>1, 
    :normal_fee=>66.00, 
    :fee=>25.00, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
  },

  # Stealth Browsers
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SBR, 
    :item_number=>"SBR.Unique-Plan", 
    :name=>"Stealth Browser Profiles", 
    :credits=>10, 
    :normal_fee=>50.00, 
    :fee=>20.00, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
  },
=end
  # Storage
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_STO, 
    :item_number=>"STO.Small-Plan", 
    :name=>"Storage MBs", 
    :credits=>512, 
    :normal_fee=>19.99, 
    :fee=>9.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_STO, 
    :item_number=>"STO.Medium-Plan", 
    :name=>"Storage MBs", 
    :credits=>1024, 
    :normal_fee=>39.99, 
    :fee=>19.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_STO, 
    :item_number=>"STO.Large-Plan", 
    :name=>"Storage MBs", 
    :credits=>2048, 
    :normal_fee=>79.99, 
    :fee=>29.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  # Simple Host Monitoring - Small
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SHM, 
    :item_number=>"SHM.Small-Plan", 
    :name=>"Small Plan", 
    :credits=>1, 
    :normal_fee=>9.99, 
    :fee=>4.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  # Simple Host Monitoring - Medium
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SHM, 
    :item_number=>"SHM.Medium-Plan", 
    :name=>"Medium Plan", 
    :credits=>10, 
    :normal_fee=>59.99, 
    :fee=>29.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  # Simple Host Monitoring - Large
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_SHM, 
    :item_number=>"SHM.Large-Plan", 
    :name=>"Large Plan", 
    :credits=>100, 
    :normal_fee=>599.99, 
    :fee=>59.99, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>[],
    #:bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  # LinkedIn Prospector
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_DRX, 
    :item_number=>"DRX.Plan-4000", 
    :name=>"Linked Prospector 4K", 
    :credits=>4000, 
    :normal_fee=>149, 
    :fee=>49, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-10", "EDB.Plan-5", "MAC.Plan-20"],
    :bonus_plans=>[
      { :item_number => "EDB.Plan-5", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_DRX, 
    :item_number=>"DRX.Plan-8000", 
    :name=>"Linked Prospector 8K", 
    :credits=>8000, 
    :normal_fee=>179, 
    :fee=>79,
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-10"],
    :bonus_plans=>[
      { :item_number => "EDB.Plan-15", :period => 1 },
      { :item_number => "MAC.Plan-20", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_DRX, 
    :item_number=>"DRX.Plan-16000", 
    :name=>"Linked Prospector 16K", 
    :credits=>15000, 
    :normal_fee=>249, 
    :fee=>149, # 0.00327 $ / invitacion
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-10"],
    :bonus_plans=>[
      { :item_number => "EDB.Plan-50", :period => 1 },
      { :item_number => "MAC.Plan-45", :period => 1 },
    ],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_EDB, 
    :item_number=>"EDB.Plan-5", 
    :name=>"5 Searches", 
    :credits=>5, 
    :normal_fee=>29, 
    :fee=>9, # 1.8 $/search 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_EDB, 
    :item_number=>"EDB.Plan-15", 
    :name=>"15 Searches", 
    :credits=>15, 
    :normal_fee=>99, 
    :fee=>19, # 1.27 $/search
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_EDB, 
    :item_number=>"EDB.Plan-50", 
    :name=>"50 Searches", 
    :credits=>50, 
    :normal_fee=>399, 
    :fee=>39, # 0.78 $/search
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_MAC, 
    :item_number=>"MAC.Plan-20", 
    :name=>"Linked Creator", 
    :credits=>20, 
    :normal_fee=>66, 
    :fee=>39, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "EDB.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_MAC, 
    :item_number=>"MAC.Plan-45", 
    :name=>"Linked Creator", 
    :credits=>45, 
    :normal_fee=>132, 
    :fee=>59, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "EDB.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_MAC, 
    :item_number=>"MAC.Plan-100", 
    :name=>"Linked Creator", 
    :credits=>100, 
    :normal_fee=>264, 
    :fee=>99, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["PVA.Plan-20", "IP6.Plan-20", "EDB.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

  #
  {
#    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION,   
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_PVA, 
    :item_number=>"PVA.Plan-10", 
    :name=>"Social Accounts", 
    :credits=>10, 
    :normal_fee=>40, 
    :fee=>20, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 12, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_PVA, 
    :item_number=>"PVA.Plan-20", 
    :name=>"Social Accounts", 
    :credits=>20, 
    :normal_fee=>60, 
    :fee=>35, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 12, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_PVA, 
    :item_number=>"PVA.Plan-50", 
    :name=>"Social Accounts", 
    :credits=>50, 
    :normal_fee=>65, 
    :fee=>50, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 12, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_PAY_AS_YOU_GO, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_PVA, 
    :item_number=>"PVA.Plan-100", 
    :name=>"Social Accounts", 
    :credits=>125, 
    :normal_fee=>135, 
    :fee=>100, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => false, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 12, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>false,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_IP6, 
    :item_number=>"IP6.Plan-20", 
    :name=>"IPv6 Social Proxies", 
    :credits=>20, 
    :normal_fee=>3, 
    :fee=>1, 
    :units=>1, 
    :period=>"M", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'M', # default D
		:expiration_lead_units => 12, # default 0
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_ACC, 
    :item_number=>"ACC.Plan-20", 
    :name=>"Social Accounts Rental", 
    :credits=>20, 
    :normal_fee=>20, 
    :fee=>10, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>1, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    #:upsells=>["DRX.Unique-Plan", "EDB.Unique-Plan", "MAC.Unique-Plan"],
    :bonus_plans=>[],
		# Force credits expiration in the moment when the client 
		# renew with a new payment from the same subscription.
		# Activate this option for every allocation service.
		:expiration_on_next_payment => true, # default true
		# Additional period after the billing cycle.
		:expiration_lead_period => 'D', # default D
		:expiration_lead_units => 7, # default 0
  },

=begin
  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_FLD, 
    :item_number=>"FLD.Unique-Plan", 
    :name=>"Leads", 
    :credits=>300, 
    :normal_fee=>79, 
    :fee=>39, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>30, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :description=>"Real-time monitor of CPU, RAM and disk space.",
    :summary=>"Real-time monitor of CPU, RAM and disk space.",
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1",
    #:upsells=>[],
    :bonus_plans=>[]
  },

  #
  {
    :type=>BlackStack::InvoicingPaymentsProcessing::BasePlan::PAYMENT_SUBSCRIPTION, 
    :public=>true,
    :one_time_offer=>false, # true: solo puede generarse un invoice-item con este plan 
    :product_code=>PRODUCT_IPJ, 
    :item_number=>"IPJ.Unique-Plan", 
    :name=>"LinkedIn Community", 
    :credits=>100, 
    :normal_fee=>299, 
    :fee=>99, 
    :units=>1, 
    :period=>"M", 
    :trial_credits=>10, 
    :trial_fee=>1, 
    :trial_units=>15, 
    :trial_period=>"D", 
    :description=>"Real-time monitor of CPU, RAM and disk space.",
    :summary=>"Real-time monitor of CPU, RAM and disk space.",
    :thumbnail=>"https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png",
    :return_path=>"#{CS_HOME_WEBSITE}/ssm3/step1",
    #:upsells=>[],
    :bonus_plans=>[]
  },
=end
])
