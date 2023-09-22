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

l = BlackStack::LocalLogger.new('./expire.log')

# process pending IPNs
while true
    begin
        # all expired payments or bonuses from accounts with 0 active subscriptions
        q = "
        select a.id as id_account, a.name as account_name, u.email, m.id as id_movement, m.type, m.service_code, m.credits, m.create_time, m.expiration_time, m.expiration_on_next_payment, count(s.id) as active_subscriptions 
        from movement m 
        join \"account\" a on a.id=m.id_account
        left join \"user\" u on u.id=a.id_user_to_contact  
        left join \"subscription\" s on (a.id=s.id_account and coalesce(s.active,false)=true)
        where m.expiration_end_time is null
        and m.expiration_time < CAST('#{now()}' as TIMESTAMP)
        and m.type in (#{BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_PAYMENT}, #{BlackStack::I2P::Movement::MOVEMENT_TYPE_ADD_BONUS})
--and a.name='ERTC Rapid Rebate'
        group by a.id, a.name, u.email, m.id, m.type, m.service_code, m.credits, m.create_time, m.expiration_time, m.expiration_on_next_payment
        having count(s.id) = 0
        order by a.name, a.id, m.create_time
        "
        DB[q].all { |row|
            l.logs "#{row[:account_name]}.#{row[:id_movement]}... "
            m = BlackStack::I2P::Movement.where(:id=>row[:id_movement]).first
            b = BlackStack::I2P::Account.where(:id=>m.id_account).first
            # update balance
            BlackStack::I2P::Account.update_balance_snapshot([b.id])
            # expire this movement
            m.expire
            l.done
        }

    rescue => e
        l.logf "Error: #{e.message}"
    end 

    l.logs 'Sleeping... '
    sleep(24*60*10) # iterate every 24 hours
    l.done

end # while true