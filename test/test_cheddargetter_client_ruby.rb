require 'helper'

class TestCheddargetterClientRuby < Test::Unit::TestCase
  
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
        :ccExpiration    => "08/2012",
        :ccCardCode      => "123",
        :ccFirstName     => "ccFirst",
        :ccLastName      => "ccLast",
        :ccZip           => cc_error ? cc_error : "11361"
      },
    }
  end
  
  should "get 3 plans from cheddar getter" do
    result = CG.get_plans
    assert_equal 3, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")['name']
    assert_equal "Test Plan 2", result.plan("TEST_PLAN_2")['name']
    assert_equal "Test Plan 1", result.plan("TEST_PLAN_1")['name']
    assert_equal nil, result.plan("NOT_A_PLAN")
    assert_equal 2, result.plan_items("TEST_PLAN_1").count
    assert_equal "Test Item 1", result.plan_item("TEST_PLAN_1", "TEST_ITEM_1")['name']
    assert_equal "Test Item 2", result.plan_item("TEST_PLAN_1", "TEST_ITEM_2")['name']
    assert_raises(CheddarGetter::ResponseException){ result.plan }
    assert_raises(CheddarGetter::ResponseException){ result.plan_items }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item("TEST_PLAN_1") }
    assert_raises(CheddarGetter::ResponseException){ result.customer }
    assert_equal true, result.valid?
  end
  
  should "get a single plan from cheddar getter" do
    assert_raises(CheddarGetter::ClientException){ CG.get_plan }
    result = CG.get_plan(:code => "FREE_PLAN_TEST")
    assert_equal 1, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")['name']
    assert_equal nil, result.plan("TEST_PLAN_2")
    assert_equal nil, result.plan("TEST_PLAN_1")
    assert_equal nil, result.plan("NOT_A_PLAN")
    assert_equal 2, result.plan_items.count
    assert_equal nil, result.plan_items("TEST_PLAN_1")
    assert_equal "Test Item 1", result.plan_item(nil, "TEST_ITEM_1")['name']
    assert_equal "Test Item 2", result.plan_item(nil, "TEST_ITEM_2")['name']
    assert_raises(CheddarGetter::ResponseException){ result.plan_item }
    assert_raises(CheddarGetter::ResponseException){ result.plan_item("FREE_PLAN_TEST") }
    assert_raises(CheddarGetter::ResponseException){ result.customer }
    assert_equal true, result.valid?
    
    result = CG.get_plan(:id => "fe96b9e6-53a2-102e-b098-40402145ee8b")
    assert_equal 1, result.plans.size
    assert_equal "Free Plan Test", result.plan("FREE_PLAN_TEST")['name']
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
    assert_equal "1", result.customer['code']
    assert_equal "Free Plan Test", result.customer_plan['name']
  end
  
  should "create a single paid customer at cheddar getter" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer['code']
    assert_equal "Test Plan 2", result.customer_plan['name']
    assert_equal "20.00", result.customer_invoice['charges'].first['eachAmount']
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
    error_codes = { 
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
    
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    error_codes.each do |k, v|
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
  
end
