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

## Signing Up to BlackStack.io

Signup to [BlackStack.io](https://blackstack.io/signup)

Upload your company information [here](https://blackstack.ip/member/clientinformation).
The contact information of your company will be shown in your invoice.
Remember to upload your company logo. It will be published in your invoice too.

Your clients may want to edit their contact information, because their company details should be shown in their invoices for taxes pourposes.
You can setup domain aliasing in order disguise the *blackstack.io* domain as *invoicing.yourdmain.com*, so your clients can signup to BlackStack, and edit their contact information, and make all of this as showning inside your website.

## IPN Processing Hooks

Even if you publish your invoices in your own website, PayPal's IPNs will be hooked and processed by the BlackStack.io service.

You can know the exact URL where PayPal will send the IPNs by running this code:

```ruby
require 'i2p'

puts BlackStack::I2P::PAYPAL_HOOKS_URL
# => http://blackstack.io:80/

puts BlackStack::I2P::paypal_ipn_listener
# => http://blackstack.io:80/api1.3/accounting/paypal/notify_new_invoice.json
```

## Setting You PayPal Account

```ruby
require 'i2p'

BlackStack::I2P::set_paypal_business_email(
	"sardi.leandro.daniel@gmail.com"	
)

puts BlackStack::I2P::paypal_business_email
# => "sardi.leandro.daniel@gmail.com"	
```

## Setting Up Products

```ruby
require 'i2p'

BlackStack::I2P::set_products([
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

puts BlackStack::I2P::products_descriptor
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
	
	# true: this plan is available only if the client has not any other invoice including this plan
	# false: this plan can be purchased many times
	:one_time_offer=>false,  
	
	# which product is this plan belong
	:product_code=>'dedicated-support', 
	
	# plan description
	:item_number=>"deducated-support.starter-plan", 
	:name=>"Dedicated Support - Starter Plan", 
	
	# billing details
	:credits=>1, # only 1 support agent
	:normal_fee=>299, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
	:fee=>99, # this is the fee that your will charge to the client, as a special offer price.
	:period=>1,
	:units=>"M", # billed monthy
},
{
	# recurrent billing plan
	:type=>BlackStack::I2P::PAYMENT_SUBSCRIPTION,  
	
	:public=>true,
	
	# true: this plan is available only if the client has not any other invoice including this plan
	# false: this plan can be purchased many times
	:one_time_offer=>false,  
	
	# which product is this plan belong
	:product_code=>'dedicated-support', 
	
	# plan description
	:item_number=>"deducated-support.enterprise-plan", 
	:name=>"Dedicated Support - Enterprise Plan", 
	
	# billing details
	:credits=>2, # Oh! 2 support agents!!
	:normal_fee=>499, # cognitive bias: expensive fee to show it strikethrough, as the normal price. But it's a lie. 
	:fee=>199, # this is the fee that your will charge to the client, as a special offer price.
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

*(pending: there is not any amount, before such credits are for free, and if the client request refund, you will not refund free credits given to the client)*

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
