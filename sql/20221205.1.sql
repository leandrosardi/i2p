-- alter table buffer_paypal_notification drop column if exists sync_reservation_id;
alter table buffer_paypal_notification add column if not exists sync_reservation_id varchar(500) null;
