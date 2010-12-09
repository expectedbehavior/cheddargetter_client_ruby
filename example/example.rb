require 'rubygems'
require 'cheddargetter_client_ruby'

FREE_PLAN = "FREE"
PAID_PLAN = "PREMIUM"

client = CheddarGetter::Client.new(:product_code => "YOUR_PRODUCT_CODE",
                                   :username => "your.username@example.com",
                                   :password => "your.password")

puts ""
puts "********************************************************************"
puts "** DELETING PREVIOUSLY CREATED EXAMPLE CUSTOMERS                  **"
puts "********************************************************************"
	
# delete customers if they're already there
response = client.delete_all_customers
if response.valid?
  puts "\tDeleted old customers"
else
  puts "\tERROR: #{response.error_message}"
end
	
puts ""
puts "********************************************************************"
puts "** CREATE CUSTOMER ON THE FREE PLAN                               **"
puts "********************************************************************"
	
# create a customer on a free plan
data = {
  :code      => 'MILTON_WADDAMS',
  :firstName => 'Milton',
  :lastName  => 'Waddams',
  :email     => 'milt@initech.com',
  :subscription => { 
    :planCode => FREE_PLAN
  }
}

response = client.new_customer(data)
if response.valid?
  puts "\tCreated Milton Waddams with code=MILTON_WADDAMS"
else
  puts "\tERROR: #{response.error_message}"
end
	
puts ""
puts "********************************************************************"
puts "** SIMULATE ERROR CREATING CUSTOMER ON PAID PLAN                  **"
puts "********************************************************************"
	
# try to create a customer on a paid plan (simulated error)
data = {
  :code      => 'BILL_LUMBERG',
  :firstName => 'Bill',
  :lastName  => 'Lumberg',
  :email     => 'bill@initech.com',
  :subscription => {
    :planCode     => PAID_PLAN,
    :ccNumber     => '4111111111111111',
    :ccExpiration => '10/2014',
    :ccCardCode   => '123',
    :ccFirstName  => 'Bill',
    :ccLastName   => 'Lumberg',
    :ccZip        => '05003' # simulates an error of "Credit card type is not accepted"
  }
}

response = client.new_customer(data)
if response.valid?
  puts "\tCreated Bill Lumberg with code=BILL_LUMBERG. (This should not have happened)"
else
  puts "\tExpect Error: #{response.error_message}"
end

puts ""
puts "********************************************************************"
puts "** CREATE CUSTOMER ON PAID PLAN AND GET CURRENT                   **"
puts "** INVOICE INFORMATION                                            **"
puts "********************************************************************"
	
data = {
  :code      => 'BILL_LUMBERG',
  :firstName => 'Bill',
  :lastName  => 'Lumberg',
  :email     => 'bill@initech.com',
  :subscription => {
    :planCode     => PAID_PLAN,
    :ccNumber     => '4111111111111111',
    :ccExpiration => '10/2014',
    :ccCardCode   => '123',
    :ccFirstName  => 'Bill',
    :ccLastName   => 'Lumberg',
    :ccZip        => '90210'
  }
}


response = client.new_customer(data)
if response.valid?
  puts "\tCreated Bill Lumberg with code=BILL_LUMBERG"
else
  puts "\tERROR: #{response.error_message}"
end
	
#get lumberg and display current details
response = client.get_customer(:code => 'BILL_LUMBERG')
if response.valid?
  customer     = response.customer
  subscription = response.customer_subscription
	plan         = response.customer_plan
	invoice      = response.customer_invoice
		
  puts "\t#{customer[:firstName]} #{customer[:lastName]}"
	puts "\tPricing Plan: #{plan[:name]}"
	puts "\tPending Invoice Scheduled: #{invoice[:billingDatetime].strftime('%m/%d/%Y')}"
  invoice[:charges].each do |charge|
    puts "\t\t(#{charge[:quantity]}) #{charge[:code]} $#{charge[:eachAmount]*charge[:quantity]}"
  end
else
  puts "\tERROR: #{response.error_message}"
end	
