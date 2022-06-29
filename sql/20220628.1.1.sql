/*
Numeric Data Type: Arbitrary Precision Numbers

The type numeric can store numbers with a very large number of digits. 
It is especially recommended for storing monetary amounts and other quantities where exactness is required. 
Calculations with numeric values yield exact results where possible, e.g., addition, subtraction, multiplication. 
However, calculations on numeric values are very slow compared to the integer types, or to the floating-point types described in the next section.

references: 
1. https://www.postgresql.org/docs/current/datatype-numeric.html
2. https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-numeric/
*/

/*
 * Use this the day we want to 1) store plans configuration on database, or 2) offer custom plans to specific clients.
 *
CREATE TABLE IF NOT EXISTS plan (
	id uuid NOT NULL,
	id_client uuid NOT NULL,
	create_time timestamp NOT NULL,
	type varchar(1) NOT NULL,
	item_number varchar(500) NOT NULL,
	name varchar(500) NOT NULL,
	credits bigint NOT NULL,
	fee numeric(22, 8) NOT NULL,
	period bigint NOT NULL,
	units varchar(1) NOT NULL,
	trial_credits bigint NULL,
	trial_fee numeric(22, 8) NULL,
	trial_period bigint NULL,
	trial_units varchar(1) NULL,
	trial2_credits bigint NULL,
	trial2_fee numeric(22, 8) NULL,
	trial2_period bigint NULL,
	trial2_units varchar(1) NULL,
	description varchar(8000) NOT NULL,
);
*/

CREATE TABLE IF NOT EXISTS buffer_paypal_notification (
	id uuid NOT NULL,
	create_time timestamp NOT NULL,
	txn_type varchar(500) NULL,
	subscr_id varchar(500) NULL,
	last_name varchar(500) NULL,
	residence_country varchar(500) NULL,
	mc_currency varchar(500) NULL,
	item_name varchar(500) NULL,
	amount1 varchar(500) NULL,
	business varchar(500) NULL,
	amount3 varchar(500) NULL,
	recurring varchar(500) NULL,
	verify_sign varchar(500) NULL,
	payer_status varchar(500) NULL,
	test_ipn varchar(500) NULL,
	payer_email varchar(500) NULL,
	first_name varchar(500) NULL,
	receiver_email varchar(500) NULL,
	payer_id varchar(500) NULL,
	invoice varchar(500) NULL,
	reattempt varchar(500) NULL,
	item_number varchar(500) NULL,
	subscr_date varchar(500) NULL,
	charset varchar(500) NULL,
	notify_version varchar(500) NULL,
	period1 varchar(500) NULL,
	mc_amount1 varchar(500) NULL,
	period3 varchar(500) NULL,
	mc_amount3 varchar(500) NULL,
	ipn_track_id varchar(500) NULL,
	transaction_subject varchar(500) NULL,
	payment_date varchar(500) NULL,
	payment_gross varchar(500) NULL,
	payment_type varchar(500) NULL,
	txn_id varchar(500) NULL,
	receiver_id varchar(500) NULL,
	payment_status varchar(500) NULL,
	payment_fee varchar(500) NULL,
	sync_reservation_id uuid NULL,
	sync_reservation_time timestamp NULL,
	sync_reservation_times int NULL,
	sync_start_time timestamp NULL,
	sync_end_time timestamp NULL,
	sync_result varchar(8000) NULL,
);

CREATE TABLE IF NOT EXISTS invoice (
	id uuid NOT NULL PRIMARY KEY,
	create_time timestamp NOT NULL,
	id_client uuid NOT NULL,
	billing_period_from date NULL,
	billing_period_to date NULL,
	id_buffer_paypal_notification uuid NULL,
	"status" int NULL,
	paypal_url varchar(8000) NULL,
	automatic_billing bit NULL,
	subscr_id varchar(500) NULL,
	disabled_for_trial_ssm bit NULL,
	disabled_for_add_remove_items bit NULL,
	id_previous_invoice uuid NULL,
	delete_time timestamp NULL,
);

CREATE TABLE IF NOT EXISTS invoice_item(
	id uuid NOT NULL PRIMARY KEY,
	id_invoice uuid NOT NULL,
	product_code varchar(5) NOT NULL,
	unit_price numeric(18, 4) NOT NULL,
	units numeric(18, 4) NOT NULL,
	amount numeric(18, 4) NOT NULL,
	detail varchar(500) NOT NULL,
	item_number varchar(500) NULL,
	description varchar(500) NULL,
	create_time timestamp NULL,
);

CREATE TABLE IF NOT EXISTS movement(
	id uuid NOT NULL PRIMARY KEY,
	id_client uuid NOT NULL,
	create_time timestamp NOT NULL,
	type int NOT NULL,
	id_user_creator uuid NULL,
	description text NULL,
	paypal1_amount numeric(22, 8) NOT NULL, -- transactions must be operated with double of precision (8 digits) stored on other tables (4 digits)
	bonus_amount numeric(22, 8) NOT NULL, -- transactions must be operated with double of precision (8 digits) stored on other tables (4 digits)
	amount numeric(22, 8) NOT NULL, -- transactions must be operated with double of precision (8 digits) stored on other tables (4 digits)
	credits bigint NOT NULL,
	lgb2_id_lngroup uuid NULL,
	edb_id_crmlist uuid NULL,
	profits_amount numeric(22, 8) NOT NULL,
	id_invoice_item uuid NULL,
	product_code varchar(500) NOT NULL,
	expiration_time timestamp NULL,
	expiration_start_time timestamp NULL,
	expiration_end_time timestamp NULL,
	expiration_tries int NULL,
	expiration_description varchar(500) NULL,
	expiration_on_next_payment bit NULL,
	expiration_lead_period varchar(500) NULL,
	expiration_lead_units int NULL,
	give_away_negative_credits bit NULL,
);