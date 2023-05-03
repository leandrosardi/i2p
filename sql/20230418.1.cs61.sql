ALTER TABLE invoice_item ALTER COLUMN service_code TYPE varchar(500);

CREATE TABLE IF NOT EXISTS balance (
    id uuid NOT NULL,
    id_account uuid NOT NULL,
    service_code varchar(500) NOT NULL,
    last_update_time timestamp NOT NULL,
    credits int8 NOT NULL,
    amount numeric(22, 8) NOT NULL,
    CONSTRAINT balance_pkey PRIMARY KEY (id ASC),
    CONSTRAINT uk_balance UNIQUE (id_account ASC, service_code ASC)
);

ALTER TABLE public.balance ADD CONSTRAINT IF NOT EXISTS balance_id_account_fkey FOREIGN KEY (id_account) REFERENCES account(id);