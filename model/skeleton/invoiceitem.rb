module BlackStack
  class InvoiceItem < Sequel::Model(:invoice_item)
    InvoiceItem.dataset = InvoiceItem.dataset.disable_insert_output
    many_to_one :invoice, :class=>:'BlackStack::Invoice', :key=>:id_invoice  
  
    def plan_descriptor()
      BlackStack::InvoicingPaymentsProcessing::plan_descriptor(self.item_number)
    end

    # Returns the number of plans ordered in this item 
    def number_of_packages()
      plan = BlackStack::InvoicingPaymentsProcessing.plan_descriptor(self.item_number)
      if self.amount.to_f == plan[:trial_fee].to_f || self.amount.to_f == plan[:trial2_fee].to_f
        return 1.to_i 
      else
        return (self.units.to_f / plan[:credits].to_f).to_i
      end
    end

  end # class LocalInvoiceItem
end # module BlackStack