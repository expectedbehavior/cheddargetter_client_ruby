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

  def paypal_new_user_hash(id, cc_error = nil)
    { 
      :code                 => id,
      :firstName            => "First",
      :lastName             => "Last",
      :email                => "buyer_1304894377_per@gmail.com",
      :firstContactDatetime => Time.now,
      :subscription => { 
        :planCode         => "TEST_PLAN_2",
        :ccFirstName      => "ccFirst",
        :ccLastName       => "ccLast",
        :method           => 'paypal',
        :returnUrl        => 'http://mywebapp.com/login?paypalAccepted',
        :cancelUrl        => 'http://mywebapp.com/login?paypalCanceled'
      },
    }
  end
    
  should 'update single paypal user' do
    result = CG.delete_all_customers
    assert_equal true, result.valid?
    
    result = CG.new_customer(paypal_new_user_hash(1))
    assert_equal true, result.valid?
    assert_equal 1, result.customers.size
    assert_equal "1", result.customer[:code]
    assert_equal "Test Plan 2", result.customer_plan[:name]
    assert_equal 20, result.customer_invoice[:charges].first[:eachAmount]
    #paypal customer should be in cancelled in paypal-wait status
    assert_equal true, result.customer_waiting_for_paypal?
    #paypal customer subscription should include an approve paypal preapproval url    
    assert_equal true, result.customer_paypal_preapproval_url.include?("https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_ap-preapproval&preapprovalkey=")


    
  end
end