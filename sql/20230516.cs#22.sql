alter table account add column if not exists update_balance_start_time timestamp null;
alter table account add column if not exists update_balance_success boolean null;
alter table account add column if not exists update_balance_end_time timestamp null;
alter table account add column if not exists update_balance_error_description varchar(8000) null;