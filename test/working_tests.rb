require File.join(File.dirname(__FILE__), 'helper')

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
      :firstContactDatetime => Time.now,
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
  
  should "test customer get filtering" do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    result = CG.new_customer(free_new_user_hash(1))
    assert_equal true, result.valid?
    
    result = CG.new_customer(free_new_user_hash(2))
    assert_equal true, result.valid?
    result = CG.cancel_subscription(:code => 2)
    assert_equal true, result.valid?
    assert_equal true, result.customer_canceled?
    
    
    result = CG.new_customer(paid_new_user_hash(3))
    assert_equal true, result.valid?
    
    result = CG.new_customer(paid_new_user_hash(4))
    assert_equal true, result.valid?
    result = CG.cancel_subscription(:code => 4)
    assert_equal true, result.valid?
    assert_equal true, result.customer_canceled?
    
    result = CG.get_customer_list
    assert_equal true, result.valid?
    assert_equal 4, result.customers.count
    assert_equal "1", result.customer(1)[:code]
    assert_equal "2", result.customer(2)[:code]
    assert_equal "3", result.customer(3)[:code]
    assert_equal "4", result.customer(4)[:code]
    
    result = CG.get_customer_list(:subscriptionStatus => "activeOnly")
    assert_equal true, result.valid?
    assert_equal 2, result.customers.count
    assert_equal "1", result.customer(1)[:code]
    assert_equal nil, result.customer(2)
    assert_equal "3", result.customer(3)[:code]
    assert_equal nil, result.customer(4)
    
    result = CG.get_customer_list(:subscriptionStatus => "canceledOnly")
    assert_equal true, result.valid?
    assert_equal 2, result.customers.count
    assert_equal nil, result.customer(1)
    assert_equal "2", result.customer(2)[:code]
    assert_equal nil, result.customer(3)
    assert_equal "4", result.customer(4)[:code]

    # result = CG.get_customer_list(:planCode => "TEST_PLAN_1")
    # assert_equal false, result.valid?
    # assert_equal ["No customers found."], result.error_messages
    # 
    # result = CG.get_customer_list(:planCode => ["TEST_PLAN_1", "TEST_PLAN_2", "FREE_PLAN_TEST"])
    # assert_equal true, result.valid?
    # assert_equal 4, result.customers.count
    
    # result = CG.get_customer_list(:planCode => "FREE_PLAN_TEST")
    # assert_equal true, result.valid?
    # assert_equal 2, result.customers.count
    # 
    # result = CG.get_customer_list(:planCode => "FREE_PLAN_TEST", :subscriptionStatus => "canceledOnly")
    # assert_equal true, result.valid?
    # assert_equal 1, result.customers.count
    
    result = CG.get_customer_list(:canceledAfterDate => Date.today)
    assert_equal true, result.valid?
    assert_equal 2, result.customers.count
    
    result = CG.get_customer_list(:createdAfterDate => Date.today)
    assert_equal true, result.valid?
    assert_equal 4, result.customers.count
    
    result = CG.get_customer_list(:search => "First")
    assert_equal true, result.valid?
    assert_equal 4, result.customers.count
    
    result = CG.get_customer_list(:search => "NotFirst")
    assert_equal false, result.valid?
    assert_equal ["No customers found."], result.error_messages
  end
end