module BlackStack
  class CustomPlan < Sequel::Model(:custom_plan)
    BlackStack::CustomPlan.dataset = BlackStack::CustomPlan.dataset.disable_insert_output
    self.dataset = self.dataset.disable_insert_output
  
    many_to_one :client, :class=>:'BlackStack::Client', :key=>:id_client
  
    def to_hash
      h = {}
      h[:type] = self.type # not null
      h[:item_number] = self.item_number # not null 
      h[:name] = self.name # not null
      h[:credits] = self.credits # not null
      h[:fee] = self.fee # not null
      h[:period] = self.period # not null
      h[:units] = self.units # not null
       
      h[:trial_credits] = self.trial_credits      if self.trial_credits != nil
      h[:trial_fee] = self.trial_fee              if self.trial_fee != nil
      h[:trial_period] = self.trial_period        if self.trial_period != nil
      h[:trial_units] = self.trial_units          if self.trial_units != nil
      
      h[:trial2_credits] = self.trial2_credits    if self.trial2_credits != nil
      h[:trial2_fee] = self.trial2_fee            if self.trial2_fee != nil
      h[:trial2_period] = self.trial2_period      if self.trial2_period != nil
      h[:trial2_units] = self.trial2_units        if self.trial2_units != nil
      
      h[:description] = self.description # not null
      h
    end
  
  end
end # module BlackStack