module BlackStack
  class Balance
  	attr_accessor :client, :product_code, :amount, :credits, :up_time
  
  	def initialize(id_client, product_code, up_time=nil)
  		self.client = BlackStack::Client.where(:id => id_client).first
  		self.product_code = product_code
			self.up_time = up_time
  		self.calculate()
  	end
  	
    def calculate()
      q = 
      "select cast(sum(cast(amount as numeric(18,12))) as numeric(18,6)) as amount, sum(credits) as credits " +
      "from movement with (nolock index(IX_movement__id_client__product_code)) " +
      "where id_client='#{self.client.id}' " +
      "and product_code='#{self.product_code}' "

			q += "and create_time < '#{self.up_time.to_time.to_sql}' " if !self.up_time.nil?

      row = DB[q].first
      self.amount = row[:amount].to_f
      self.credits = row[:credits].to_f
      # libero recursos
      DB.disconnect
      GC.start
    end
  end	
end # module BlackStack


