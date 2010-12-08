module CheddarGetter
  class Response
    SPECIAL = {
      "plans" => "plan", 
      "items" => "item",
      "subscriptions" => "subscription",
      "customers" => "customer",
      "invoices" => "invoice",
      "charges" => "charge",
      "transactions" => "transaction"
    }
    
    attr_accessor :raw_response, :clean_response
    
    def initialize(response)
      self.raw_response = response
      self.clean_response = response.parsed_response.is_a?(Hash) ? fix_keys(response.parsed_response) : { }
    end
    
    def valid?
      !self['error'] && raw_response.code == 200
    end
    
    def error_message
      self['error'] || raw_response.code
    end
    
    def plans
      self['plans']
    end
    
    def customers
      self['customers']
    end
    
    def plan(code = nil)
      retrieve_item(self, 'plans', code)
    end
    
    def plan_items(code = nil)
      (plan(code) || { })['items']
    end
    
    def plan_item(code = nil, item_code = nil)
      retrieve_item(plan(code), 'items', item_code)
    end
    
    def customer(code = nil)
      retrieve_item(self, 'customers', code)
    end
    
    def customer_subscription(code = nil)
      retrieve_item(customer(code), 'subscriptions')
    end
    
    def customer_subscriptions(code = nil)
      (customer(code) || { })['subscriptions']
    end
    
    def customer_plan(code = nil)
      retrieve_item(customer_subscription(code), 'plans')
    end
    
    def customer_invoice(code = nil)
      ((customer_subscription(code) || { })['invoices'] || []).first
    end
    
    def customer_invoices(code = nil)
      customer_subscriptions(code).map{ |s| s['invoices'] || [] }.flatten
    end
    
    def customer_last_billed_invoice(code = nil)
      customer_invoices(code)[1]
    end
    
    def customer_transactions(code = nil)
      customer_invoices(code).map{ |s| s['transactions'] || [] }.flatten
    end
    
    def customer_last_transaction(code = nil)
      invoice = customer_last_billed_invoice(code) || { }
      (invoice['transactions'] || []).first
    end
    
    def customer_outstanding_invoices(code = nil)
      now = DateTime.now
      customer_invoices(code).reject do |i| 
        i['paidTransactionId'] || i['billingDatetime'].to_datetime > now
      end
    end
    
    def customer_item_quantity(code = nil, item_code = nil)
      sub = customer_subscription(code)
      return nil unless sub
      sub_item = retrieve_item(sub, 'items', item_code)
      plan_item = retrieve_item(retrieve_item(sub, 'plans'), 'items', item_code)
      return nil unless sub_item && plan_item
      item = plan_item.dup
      item["quantity"] = sub_item["quantity"]
      item
    end
    
    def customer_item_quantity_remaining(code = nil, item_code = nil)
      item = customer_item_quantity(code, item_code)
      item ? item["quantityIncluded"].to_f - item["quantity"].to_f : 0
    end
    
    def customer_item_quantity_overage(code = nil, item_code = nil)
      over = -customer_item_quantity_remaining(code, item_code)
      over = 0 if over <= 0
      over
    end
    
    def customer_item_quantity_overage_cost(code = nil, item_code = nil)
      item = customer_item_quantity(code, item_code)
      overage = customer_item_quantity_overage(code, item_code)
      item['overageAmount'].to_f * overage
    end
    
    def [](value)
      self.clean_response[value]
    end
    
    
    private
    def fix_keys(hash)
      hash.each do |k, v|
        if v.is_a?(Hash)
          if SPECIAL.keys.include?(k) && v.keys.size == 1 && v[SPECIAL[k]]
            hash[k] = v = [v[SPECIAL[k]]].flatten
          else
            fix_keys(v)
          end
        end
        
        if v.is_a?(Array)
          v.each do |i|
            fix_keys(i) if i.is_a?(Hash)
          end
        end
      end
    end
    
    def retrieve_item(hash, type, code = nil)
      array = hash[type]
      if !array
        raise CheddarGetter::ResponseException.new(
          "Can't get #{type} from a response that doesn't contain #{type}")
      elsif code
        code = code.to_s
        array.detect{ |p| p['code'].to_s == code }
      elsif array.size <= 1
        array.first
      else
        raise CheddarGetter::ResponseException.new(
          "This response contains multiple #{type} so you need to provide the code for the one you wish to get")
      end
    end
  end
end
