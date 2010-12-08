require 'helper'

class TestCheddargetterClientRuby < Test::Unit::TestCase
  ERROR_CODES = { 
    1000 => "An unexpected error occured.  Please try again later.",
    1001 => "The record already exists",
    1002 => "An unexpected error occured.  Please try again later.",
    1003 => "An unexpected error occured.  Please try again later.",
    2000 => "The local gateway configuration is incompatible",
    2001 => "The configuration at the gateway is incompatible",
    2002 => "Authentication to the gateway failed",
    2003 => "The gateway has denied access",
    3000 => "The response from the gateway was not recognized",
    4000 => "The connection to the gateway failed.  Please try again later.",
    5000 => "There was an error processing the transaction",
    5001 => "Credit card number is invalid",
    5002 => "Expiration date is invalid",
    5003 => "Credit card type is not accepted",
    6000 => "The transaction was declined",
    6001 => "The transaction was declined due to AVS mismatch",
    6002 => "The transaction was declined due to card code verification failure",
    7000 => "The transaction failed for an unknown reason"
  }
  
  def free_new_user_hash(id)
    { 
      :code                 => id,
      :firstName            => "First",
      :lastName             => "Last",
      :email                => "email@example.com",
      :subscription => { 
        :planCode        => "FREE_PLAN_TEST",
      },
    }
  end
  
  def paid_new_user_hash(id, cc_error = nil)
    { 
      :code                 => id,
      :firstName            => "First",
      :lastName             => "Last",
      :email                => "email@example.com",
      :subscription => { 
        :planCode        => "TEST_PLAN_2",
        :ccNumber        => "4111111111111111",
        :ccExpiration    => Date.parse("08/2012"),
        :ccCardCode      => "123",
        :ccFirstName     => "ccFirst",
        :ccLastName      => "ccLast",
        :ccZip           => cc_error ? cc_error : "11361"
      },
    }
  end
  
  should "check various client init exceptions" do
    assert_raises(CheddarGetter::ClientException) do
      CheddarGetter::Client.new(:product_code => "code", :password => "password")
    end
    
    assert_raises(CheddarGetter::ClientException) do
      CheddarGetter::Client.new(:product_code => "code", :username => "username")
    end
    
    assert_raises(CheddarGetter::ClientException) do
      CheddarGetter::Client.new(:username => "username", :password => "password")
    end
    
    assert_not_nil CheddarGetter::Client.new(:username => "u", :password => "p", :product_code => "c")
    assert_not_nil CheddarGetter::Client.new(:username => "u", :password => "p", :product_id => "i")
    
    cg = CheddarGetter::Client.new(:username => "username", :password => "password", :product_code => "code")
    cg.product_code = nil
    assert_raises(CheddarGetter::ClientException) { cg.get_plans }
    cg.product_code = "code"
    
    result = cg.get_plans
    assert_equal false, result.valid?
    assert_equal "Authentication required", result.error_message
    
    cg.username = CG.username
    cg.password = CG.password
    result = cg.get_plans
    assert_equal false, result.valid?
    assert_equal "User michael@expectedbehavior.com does not have access to productCode=code", result.error_message
    
    cg.product_code = ""
    result = cg.get_plans
    assert_equal false, result.valid?
    assert_equal "No product selected. Need a productId or productCode.", result.error_message
    
    cg.product_code = nil
    cg.product_id = "id"
    result = cg.get_plans
    assert_equal false, result.valid?
    assert_equal "User does not have access to productId=id", result.error_message
  end
  
  should "get 3 plans from cheddar getter" do
    result = CG.get_plans
    assert_equal 3, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")[:name]
    assert_equal "Test Plan 2", result.plan("TEST_PLAN_2")[:name]
    assert_equal "Test Plan 1", result.plan("TEST_PLAN_1")[:name]
    assert_equal nil, result.plan("NOT_A_PLAN")
    assert_equal 2, result.plan_items("TEST_PLAN_1").count
    assert_equal "Test Item 1", result.plan_item("TEST_ITEM_1", "TEST_PLAN_1")[:name]
    assert_equal "Test Item 2", result.plan_item("TEST_ITEM_2", "TEST_PLAN_1")[:name]
    assert_raises(CheddarGetter::ResponseException){ result.plan }
    assert_raises(CheddarGetter::ResponseException){ result.plan_items }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item("TEST_ITEM_1") }
    assert_raises(CheddarGetter::ResponseException){ result.customer }
    assert_equal true, result.valid?
  end
  
  should "get a single plan from cheddar getter" do
    assert_raises(CheddarGetter::ClientException){ CG.get_plan }
    result = CG.get_plan(:code => "FREE_PLAN_TEST")
    assert_equal 1, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")[:name]
    assert_equal nil, result.plan("TEST_PLAN_2")
    assert_equal nil, result.plan("TEST_PLAN_1")
    assert_equal nil, result.plan("NOT_A_PLAN")
    assert_equal 2, result.plan_items.count
    assert_equal nil, result.plan_items("TEST_PLAN_1")
    assert_equal "Test Item 1", result.plan_item("TEST_ITEM_1")[:name]
    assert_equal "Test Item 2", result.plan_item("TEST_ITEM_2")[:name]
    assert_raises(CheddarGetter::ResponseException){ result.plan_item }
    assert_raises(CheddarGetter::ResponseException){ result.customer }
    assert_equal true, result.valid?
    
    result = CG.get_plan(:id => "fe96b9e6-53a2-102e-b098-40402145ee8b")
    assert_equal 1, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")[:name]
    assert_equal true, result.valid?
    
    result = CG.get_plan(:code => "NOT_A_PLAN")
    assert_equal false, result.valid?
    assert_equal "Plan not found for code=NOT_A_PLAN within productCode=GEM_TEST", result.error_message
  end
  
  should "create a single free customer at cheddar getter" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    result = CG.new_customer(free_new_user_hash(1))
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer[:code]
    assert_equal "Free Plan Test", result.customer_plan[:name]
  end
  
  should "create a single paid customer at cheddar getter" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer[:code]
    assert_equal "Test Plan 2", result.customer_plan[:name]
    assert_equal 20, result.customer_invoice[:charges].first[:eachAmount]
  end
  
  should "try to create a customer with various errors" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    data = paid_new_user_hash(1)
    data[:subscription].delete(:ccCardCode)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccCardCode]", result.error_message
    
    data[:subscription][:ccExpiration] = "00/0000"
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal("'00/0000' is not a valid date in format MM/YYYY: subscription[ccExpiration]", 
                 result.error_message)
    
    data[:subscription].delete(:ccExpiration)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccExpiration]", result.error_message
    
    data[:subscription][:ccNumber] = "1"
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal("'1' is not from an allowed institute: subscription[ccNumber]", 
                 result.error_message)
    
    data[:subscription].delete(:ccNumber)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccNumber]", result.error_message
    
    data[:subscription].delete(:ccZip)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccZip]", result.error_message
    
    data[:subscription].delete(:ccLastName)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccLastName]", result.error_message
    
    data[:subscription].delete(:ccFirstName)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: subscription[ccFirstName]", result.error_message
    
    data.delete(:email)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: email", result.error_message
    
    data.delete(:code)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: code", result.error_message
    
    data.delete(:lastName)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: lastName", result.error_message
    
    data.delete(:firstName)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A value is required: firstName", result.error_message
    
    data[:subscription][:planCode] = "NOT_A_PLAN"
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "No plan found with code=NOT_A_PLAN", result.error_message

    data[:subscription].delete(:planCode)
    result = CG.new_customer(data)
    assert_equal false, result.valid?
    assert_equal "A pricing plan is required", result.error_message
  end
  
  should "try to create a customer with direct forced card errors" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    ERROR_CODES.each do |k, v|
      result = CG.new_customer(paid_new_user_hash(1, "0#{k}"))
      assert_equal false, result.valid?
      assert_equal v, result.error_message
    end

  end
  
  should "try to create two customers with same code" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal true, result.valid?
    
    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal false, result.valid?
    assert_equal "Another customer already exists with code=1: code", result.error_message
  end
  
  should "get customers from cheddargetter" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?

    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal true, result.valid?
    
    result = CG.new_customer(paid_new_user_hash(2))
    assert_equal true, result.valid?
    
    result = CG.new_customer(free_new_user_hash(3))
    assert_equal true, result.valid?
    
    result = CG.get_customers
    assert_equal true, result.valid?
    assert_equal 3, result.customers.count
    assert_equal "1", result.customer(1)[:code]
    assert_equal "2", result.customer(2)[:code]
    assert_equal "3", result.customer(3)[:code]
    assert_equal nil, result.customer(4)
    assert_equal "Free Plan Test", result.customer_plan(3)[:name]
    assert_equal "Test Plan 2", result.customer_plan(2)[:name]
    assert_equal "Test Plan 2", result.customer_plan(1)[:name]
    assert_equal nil, result.customer_plan(0)
    
    #fail cause there are no plans in this response
    assert_raises(CheddarGetter::ResponseException){ result.plan }
    assert_raises(CheddarGetter::ResponseException){ result.plan_items }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item }
    
    assert_equal "Test Plan 2", result.customer_subscription(1)[:plans][0][:name]
    assert_equal 1, result.customer_subscriptions(1).count
    assert_equal "TEST_PLAN_2_RECURRING", result.customer_invoice(1)[:charges][0][:code]
    assert_equal 1, result.customer_invoices(1).count
    assert_equal nil, result.customer_last_billed_invoice(1)
    assert_equal [], result.customer_transactions(1)
    assert_equal nil, result.customer_last_transaction(1)
    assert_equal [], result.customer_outstanding_invoices(1)
    assert_raises(CheddarGetter::ResponseException){ result.customer_item("TEST_ITEM_1") }
    assert_equal "Test Item 1", result.customer_item("TEST_ITEM_1", 1)[:name]
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_remaining("TEST_ITEM_1") }
    assert_equal 0, result.customer_item_quantity_remaining("TEST_ITEM_1", 1)
    assert_equal 10, result.customer_item_quantity_remaining("TEST_ITEM_2", 1)
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage("TEST_ITEM_1") }
    assert_equal 0, result.customer_item_quantity_overage("TEST_ITEM_1", 1)
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage_cost("TEST_ITEM_1") }
    assert_equal 0, result.customer_item_quantity_overage_cost("TEST_ITEM_1", 1)
    
    assert_equal nil, result.customer_item("NOT_AN_ITEM", 1)
    assert_equal 0, result.customer_item_quantity_remaining("NOT_AN_ITEM", 1)
    assert_equal 0, result.customer_item_quantity_overage("NOT_AN_ITEM", 1)
    assert_equal 0, result.customer_item_quantity_overage_cost("NOT_AN_ITEM", 1)
    
    #all fail cause there are multiple customers atm
    assert_raises(CheddarGetter::ResponseException){ result.customer }
    assert_raises(CheddarGetter::ResponseException){ result.customer_subscription }
    assert_raises(CheddarGetter::ResponseException){ result.customer_subscriptions }
    assert_raises(CheddarGetter::ResponseException){ result.customer_plan }
    assert_raises(CheddarGetter::ResponseException){ result.customer_invoice }
    assert_raises(CheddarGetter::ResponseException){ result.customer_invoices }
    assert_raises(CheddarGetter::ResponseException){ result.customer_last_billed_invoice }
    assert_raises(CheddarGetter::ResponseException){ result.customer_transactions }
    assert_raises(CheddarGetter::ResponseException){ result.customer_last_transaction }
    assert_raises(CheddarGetter::ResponseException){ result.customer_outstanding_invoices }
    assert_raises(CheddarGetter::ResponseException){ result.customer_item }
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_remaining }
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage }
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage_cost }
  end
  
  should "get a customer from cheddargetter" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?

    result = CG.new_customer(paid_new_user_hash(5))
    assert_equal true, result.valid?
    
    assert_raises(CheddarGetter::ClientException){ CG.get_customer }
    result = CG.get_customer(:code => 6)
    assert_equal false, result.valid?
    assert_equal "Customer not found", result.error_message

    result = CG.get_customer(:code => 5)
    assert_equal true, result.valid?
    assert_equal "5", result.customer(5)[:code]
    assert_equal "5", result.customer[:code]
    
    assert_equal "Test Plan 2", result.customer_subscription[:plans][0][:name]
    assert_equal 1, result.customer_subscriptions.count
    assert_equal "Test Plan 2", result.customer_plan[:name]
    assert_equal "TEST_PLAN_2_RECURRING", result.customer_invoice[:charges][0][:code]
    assert_equal 1, result.customer_invoices.count
    assert_equal nil, result.customer_last_billed_invoice
    assert_equal [], result.customer_transactions
    assert_equal nil, result.customer_last_transaction
    assert_equal [], result.customer_outstanding_invoices
    assert_raises(CheddarGetter::ResponseException){ result.customer_item }
    assert_equal "Test Item 1", result.customer_item("TEST_ITEM_1")[:name]
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_remaining }
    assert_equal 0, result.customer_item_quantity_remaining("TEST_ITEM_1")
    assert_equal 10, result.customer_item_quantity_remaining("TEST_ITEM_2")
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage }
    assert_equal 0, result.customer_item_quantity_overage("TEST_ITEM_1")
    assert_raises(CheddarGetter::ResponseException){ result.customer_item_quantity_overage_cost }
    assert_equal 0, result.customer_item_quantity_overage_cost("TEST_ITEM_1")
    
    assert_equal nil, result.customer_item("NOT_AN_ITEM")
    assert_equal 0, result.customer_item_quantity_remaining("NOT_AN_ITEM")
    assert_equal 0, result.customer_item_quantity_overage("NOT_AN_ITEM")
    assert_equal 0, result.customer_item_quantity_overage_cost("NOT_AN_ITEM")
    
    result = CG.get_customer(:id => result.customer[:id])
    assert_equal true, result.valid?
    assert_equal "5", result.customer[:code]
        
    result = CG.get_customer(:id => "bad_id")
    assert_equal false, result.valid?
    assert_equal "Customer not found", result.error_message
  end
  
end
