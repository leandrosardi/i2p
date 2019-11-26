module BlackStack
  class InvoiceItem < Sequel::Model(:invoice_item)
    InvoiceItem.dataset = InvoiceItem.dataset.disable_insert_output
    many_to_one :invoice, :class=>:'BlackStack::Invoice', :key=>:id_invoice  
  
    def plan_descriptor()
      BlackStack::InvoicingPaymentsProcessing::plan_descriptor(self.item_number)
    end

  end # class LocalInvoiceItem
end # module BlackStack