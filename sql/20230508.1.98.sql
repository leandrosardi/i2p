alter table "account" add column if not exists billing_address varchar(500) null;
alter table "account" add column if not exists billing_city varchar(500) null;
alter table "account" add column if not exists billing_state varchar(500) null;
alter table "account" add column if not exists billing_zipcode varchar(500) null;
alter table "account" add column if not exists billing_country varchar(500) null;
