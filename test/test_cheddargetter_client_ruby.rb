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
    result = CG.new_customer(free_new_user_hash(1))
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer['code']
    assert_equal "Free Plan Test", result.customer_plan['name']
    result = CG.delete_all_customers
    assert true, result.valid?
  end
  
  should "create a single paid customer at cheddar getter" do
    result = CG.new_customer(paid_new_user_hash(1))
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer['code']
    assert_equal "Test Plan 2", result.customer_plan['name']
    assert_equal "20.00", result.customer_invoice['charges'].first['eachAmount']
    result = CG.delete_all_customers
    assert true, result.valid?
  end
  
end
