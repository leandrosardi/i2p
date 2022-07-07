module BlackStack
  module I2P
    class Balance
      attr_accessor :account, :product_code, :amount, :credits, :up_time
    
      def initialize(id_account, product_code, up_time=nil)
        self.account = BlackStack::MySaaS::Account.where(:id => id_account).first
        self.product_code = product_code
        self.up_time = up_time
        self.calculate
      end
      
      def calculate()
        q1 = nil
        q2 = nil
        q1 = "
          select cast(sum(cast(amount as numeric(18,12))) as numeric(18,6)) as amount 
          from movement 
          where id_account='#{self.account.id}' 
          and product_code='#{self.product_code}' 
          and create_time <= '#{self.up_time.nil? ? now : self.up_time.to_time.to_sql}' 
        "
        q2 = " 
          select sum(credits) as credits 
          from movement 
          where id_account='#{self.account.id}' 
          and product_code='#{self.product_code}' 
          and create_time <= '#{self.up_time.nil? ? now : self.up_time.to_time.to_sql}' 
        "
        row1 = DB[q1].first
        row2 = DB[q2].first
        self.amount = row1[:amount].to_f
        self.credits = row2[:credits].to_f
        # libero recursos
        DB.disconnect
        GC.start
      end
    end	# class Balance
  end # module I2P
end # module BlackStack


