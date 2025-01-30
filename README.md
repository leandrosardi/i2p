![Gem version](https://img.shields.io/gem/v/i2p) ![Gem downloads](https://img.shields.io/gem/dt/i2p)

# Invoicing Payments Processing

**Invoicing and Payments Processing** gem (a.k.a. **I+2P**) is a Ruby gem to setup amazing offers in your website, track them, and also process payments automatically using PayPal.

This gem is part of the **BlackStack** framework.

You can setup the invoices using this Gem.
You will need a BlackStack account to grab and publish the invoices in your website.
The BlackStack.io will also receive the IPN notifications and process your payments.

## Installing

```
gem install i2p
```

## Setting Up

```ruby
require 'i2p'

# I2P configuration
# 
BlackStack::I2P::set({
  # In PROD environment: use your public domain.
  # IN DEV environment: user your ngrok domain.
  #
  # ## For you DEV environment, set Up both Facilitator and Buyer accounts:
  # 1. Login to developer.paypal.com.
  # 2. Go to https://developer.paypal.com/developer/accounts
  #
  # ## Activate IPN:
  # 1. Login to your PayPal account (if you are working on dev, login to sandbox.paypal.com using your facilitator email address).
  # 2. Go Here: https://www.paypal.com/cgi-bin/customerprofileweb?cmd=_profile-ipn-notify
  # (or https://sandbox.paypal.com/cgi-bin/customerprofileweb?cmd=_profile-ipn-notify if you are in dev)
  # Reference: https://developer.paypal.com/api/nvp-soap/ipn/IPNTesting/
  #
  # ## How to Find the IPNs
  # 1. Login to your PayPal account (if you are working on dev, login to sandbox.paypal.com using your facilitator email address).
  # 2. Go Here: https://www.paypal.com/us/cgi-bin/webscr?cmd=_display-ipns-history
  # (or https://sandbox.paypal.com/us/cgi-bin/webscr?cmd=_display-ipns-history if you are in dev)
  #
  'paypal_ipn_listener' => ( BlackStack.sandbox? ? 'https://b5f4-181-164-172-11.ngrok-free.app' : CS_HOME_WEBSITE) + '/api1.0/i2p/ipn.json',

  # In PROD environment: use your paypal.com email account.
  # IN DEV environment: use your sandbox.paypal.con email address.
  'paypal_business_email' => BlackStack.sandbox? ? 'sardi.leandro.daniel-facilitator@gmail.com' : 'sardi.leandro.daniel@gmail.com',

  # In PROD environment: use https://www.paypal.com.
  # In DEV environment: use https://www.sandbox.paypal.com.
  # More information here: https://developer.paypal.com/doapp/business/test-and-go-live/sandbox/
  'paypal_orders_url' => BlackStack.sandbox? ? 'https://sandbox.paypal.com' : 'https://www.paypal.com',
})
```

## Setting Up Products

```ruby
require 'i2p'

BlackStack::I2P::add_services([
{ 
	:code=>'dedicated-support', 
	:name=>'Dedicated Support', 
	:unit_name=>'support agents', 
	:consumption=>BlackStack::I2P::CONSUMPTION_BY_TIME, 
	:type=>BlackStack::I2P::PRODUCT_AGENCY,
	:description=>'Dedicated Support, Consultancy & Campaigns Management.',
	:summary=>'Get One Account Manager for Your Campaigns.',
	:thumbnail=>'https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png',
	:return_path=>'https://yourwebsite.com/dedicated-support/welcome',
},
{ 
	:code=>'2020-event-ticket', 
	:name=>'Ticket to the BlackStack eCommerce Summit 2020', 
	:unit_name=>'tickets', 
	:consumption=>BlackStack::I2P::CONSUMPTION_BY_UNIT, 
	:type=>BlackStack::I2P::PRODUCT_WAREHOUSE,
	:description=>'Ticket to the BlackStack eCommerce Summit 2020. Live Streaming of all the Converences.', 
	:summary=>'The BlackStack eCommerce Summit is the larger event about building aggressive and cost effective marketing strategies using the BlackStack framework and many other resources.',
	:thumbnail=>'https://portfolio-openxcell.s3.amazonaws.com/resource/77/cover/cover.png',
	:return_path=>'https://yourwebsite.com/event2020/step1',
}])

puts BlackStack::I2P::services_descriptor
# => [{...}, {...}]	
```

## Setting Up Plans

```ruby
require 'i2p'

BlackStack::I2P::set_plans([
# Dedicated Support
{
	# recurrent billing plan
	:type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
	
	:public=>true,
	
	# true: this plan is available only if the account has not any other invoice including this plan
	# false: this plan can be purchased many times
	:one_time_offer=>false,  
	
	# which product is this plan belong
	:service_code=>'dedicated-support', 
	
	# plan description
	:item_number=>"deducated-support.starter-plan", 
	:name=>"Dedicated Support - Starter Plan", 
	
	# billing details
	:credits=>1, # only 1 support agent
	:normal_fee=>299, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
	:fee=>99, # this is the fee that your will charge to the account, as a special offer price.
	:period=>1,
	:units=>"M", # billed monthy
},
{
	# recurrent billing plan
	:type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
	
	:public=>true,
	
	# true: this plan is available only if the account has not any other invoice including this plan
	# false: this plan can be purchased many times
	:one_time_offer=>false,  
	
	# which product is this plan belong
	:service_code=>'dedicated-support', 
	
	# plan description
	:item_number=>"deducated-support.enterprise-plan", 
	:name=>"Dedicated Support - Enterprise Plan", 
	
	# billing details
	:credits=>2, # Oh! 2 support agents!!
	:normal_fee=>499, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
	:fee=>199, # this is the fee that your will charge to the account, as a special offer price.
	:period=>1,
	:units=>"M", # billed monthy
}])

puts BlackStack::I2P::plans_descriptor
# => [{...}, {...}]	
```


## Submit Configuration

*(pending: store the products and plans in the database)*

## Creating an Invoice

*(pending: call the creation of an invoice, get URL to the invoice)*

## Setting Up Trials

*(pending)*

## Setting Up TripWires

*(pending)*

## Setting Up UpSells

*(pending)*

## Setting Up Additional Bonuses

*(pending)*

## Getting Your List of Clients

*(pending)*

## Setting Up Custom Plans

*(pending)*

## Getting Your List of Invoices

*(pending)*

## Registering Clint Consumption

*(pending)*

## Getting a Client Balance

*(pending)*

## Processing Payments

*(pending)*

## Processing Refunds

*(pending: issue when there is more than 1 item, and the refund amount doesn't match with any of the itema)*

## Understanding Accounting

### Registering Payments

*(pending: explain some first balance columns in this first section)*

### Registering Consumption

*(pending: explain the profirs column in this section, and how the credit value is calculated)*

### Registering Refunds

*(pending: explain partial and full refunds, explain the problem of 'partial refunds of invoices with more than 1 item')*

### Registering Bonus

*(pending: there is not any amount, before such credits are for free, and if the account request refund, you will not refund free credits given to the account)*

### Moving Credits Betwheen Services

*(pending: it will create 2 movments: first a 'deduction movement', and then a 'bonus-with-credits movment')*

## Appendix 1: Avoiding Cumulative Rounding Errors 

To avoid [cumulative rounding errors](https://math.stackexchange.com/questions/3032627/how-to-avoid-cumulative-rounding-errors-when-calculating-a-result-to-a-specific), we calculate numbers with double of the precision stored in database.

The data type numeric can store numbers with a very large number of digits. 

It is especially recommended for storing monetary amounts and other quantities where exactness is required. 
Calculations with numeric values yield exact results where possible, e.g., addition, subtraction, multiplication. 
However, calculations on numeric values are very slow compared to the integer types, or to the floating-point types described in the next section.

references: 
1. https://www.postgresql.org/docs/current/datatype-numeric.html
2. https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-numeric/


## Further Readings

[Identifying Your IPN Listener to PayPal](https://developer.paypal.com/docs/ipn/integration-guide/IPNSetup/)

[IPN Operations/History on PayPal](https://developer.paypal.com/docs/api-basics/notifications/ipn/IPNOperations/#:~:text=Resend%20IPN%20messages-,View%20IPN%20messages%20and%20details,status%2C%20and%20PayPal%20transaction%20ID.)
