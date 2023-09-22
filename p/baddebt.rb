# Reference: https://github.com/leandrosardi/cs/issues/69

# load gem and connect database
require 'app/mysaas'
require 'app/lib/stubs'
require 'app/config'
require 'app/version'
DB = BlackStack::CRDB::connect
require 'app/lib/skeletons'
require 'app/extensions/i2p/lib/skeletons'

# add required extensions
BlackStack::Extensions.append :i2p

l = BlackStack::LocalLogger.new('./baddebt.log')

# process pending IPNs
while true
    begin
        # all the records in the table `buffer_paypal_notification` with `txn_type='subscr_failed', happened 2 times, and where the last one happened 6 days ago.
        q = "
        select b.subscr_id, count(b.id) as n, max(b.create_time) as last_ipn
        from buffer_paypal_notification b 
        join \"subscription\" s on (s.subscr_id=b.subscr_id and coalesce(s.active,false)=true) 
        where b.txn_type='subscr_failed' 
        group by b.subscr_id
        having max(b.create_time) < current_timestamp - interval '6 days'
        order by max(b.create_time)
        "
        DB[q].all { |row|
            subscr_id = row[:subscr_id]
            count = row[:n]
            max_create_time = row[:last_ipn]
            l.logs "Processing subscr_id #{subscr_id}... "
            days = (Time.now - max_create_time).to_f / (24*60*60).to_f
            #l.logf "count: #{count}, max_create_time: #{max_create_time}, days ago:#{(days)}"
            if days < 6
                l.logf "skipping, last IPN happened #{days} days ago."
            else
                DB.execute("update \"subscription\" set active=false where subscr_id='#{subscr_id}'")
                l.logf "deactivating subscription #{subscr_id}"
            end
        }

    rescue => e
        l.logf "Error: #{e.message}"
    end 

    l.logs 'Sleeping... '
    sleep(24*60*10) # iterate every 24 hours
    l.done

end # while true