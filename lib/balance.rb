module BlackStack
  class Balance
  	attr_accessor :client, :product_code, :amount, :credits, :up_time
  
  	def initialize(id_client, product_code, up_time=nil)
  		self.client = BlackStack::Client.where(:id => id_client).first
  		self.product_code = product_code
			self.up_time = up_time
  		self.calculate()
  	end
  	
    def calculate(use_stat_balance=true)
      q1 = nil
      q2 = nil

      if !self.up_time.nil? || !use_stat_balance
        q1 = 
        "select cast(sum(cast(amount as numeric(18,12))) as numeric(18,6)) as amount " +
        "from movement with (nolock index(IX_movement__id_client__product_code__create_time__amount)) " +
        "where id_client='#{self.client.id}' " +
        "and product_code='#{self.product_code}' " +
  			"and create_time <= '#{self.up_time.to_time.to_sql}' "

        q2 = 
        "select sum(credits) as credits " +
        "from movement with (nolock index(IX_movement__id_client__product_code__create_time__credits)) " +
        "where id_client='#{self.client.id}' " +
        "and product_code='#{self.product_code}' " +
  			"and create_time <= '#{self.up_time.to_time.to_sql}' "
      else
        q1 = 
        "select cast(sum(cast(amount as numeric(18,12))) as numeric(18,6)) as amount " +
        "from stat_balance x with (nolock index(IX_movement__id_client__product_code__create_time__amount)) " +
        "where x.id_client='#{self.client.id}' " +
        "and x.product_code='#{self.product_code}' "

        q2 = 
        "select sum(credits) as credits " +
        "from stat_balance x with (nolock index(IX_movement__id_client__product_code__create_time__credits)) " +
        "where x.id_client='#{self.client.id}' " +
        "and x.product_code='#{self.product_code}' "
      end
      row1 = DB[q1].first
      row2 = DB[q2].first
      self.amount = row1[:amount].to_f
      self.credits = row2[:credits].to_f
      # libero recursos
      DB.disconnect
      GC.start
    end
  end	
end # module BlackStack


