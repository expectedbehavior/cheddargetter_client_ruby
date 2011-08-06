module CheddarGetter
  class Client
    include HTTParty
    
    base_uri "https://cheddargetter.com/"
    attr_accessor :product_code, :product_id, :username, :password
    
    #options:
    #
    #{
    #  :username     => required, your CheddarGetter username
    #  :password     => required, your CheddarGetter password
    #  :product_id   => this or product_code is required
    #  :product_code => this or product_id is required
    #}
    def initialize(options = { })
      self.product_code = options[:product_code]
      self.product_id   = options[:product_id]
      self.username     = options[:username]
      self.password     = options[:password]
      
      raise CheddarGetter::ClientException.new(":username is required") unless self.username
      raise CheddarGetter::ClientException.new(":password is required") unless self.password
      unless self.product_code || self.product_id
        raise CheddarGetter::ClientException.new(":product_code or :product_id are required") 
      end
    end
    
    #https://cheddargetter.com/developers#all-plans
    def get_plans
      do_request(:item => :plans, :action => :get)
    end

    #https://cheddargetter.com/developers#single-plan
    #
    #id_hash: {:code => plan_code} OR {:id => plan_id}
    def get_plan(id_hash = { })
      do_request(:item => :plans, :action => :get, :id_hash => id_hash)
    end

    #https://cheddargetter.com/developers#all-customers
    #
    #Any, all, or none of this data hash can be given.
    #It just filters the returned customers
    #
    #data:
    #
    #{
    #  :subscriptionStatus => "activeOnly" or "canceledOnly",
    #  :planCode           => plan_code, #can take an array of plan codes
    #  :createdAfterDate	 => date,
    #  :createdBeforeDate  => date,
    #  :canceledAfterDate  => date,
    #  :canceledBeforeDate =>	date,
    #  :orderBy	           =>	"name" (default), "company", "plan", "billingDatetime" or "createdDatetime"
    #  :orderByDirection   =>	"asc" (default) or "desc"
    #  :search             =>	Tcustomer name, company, email address and last four digits of credit card.
    #}
    def get_customers(data = nil)
      warn 'Deprecation Warning: get_customers method is deprecated. Use get_customer_list instead'
      do_request(:item => :customers, :action => :get, :data => data)
    end

    #https://cheddargetter.com/developers#all-customers
    #
    #Any, all, or none of this data hash can be given.
    #It just filters the returned customers
    #
    #data:
    #
    #{
    #  :subscriptionStatus => "activeOnly" or "canceledOnly",
    #  :planCode           => plan_code, #can take an array of plan codes
    #  :createdAfterDate	 => date,
    #  :createdBeforeDate  => date,
    #  :canceledAfterDate  => date,
    #  :canceledBeforeDate =>	date,
    #  :orderBy	           =>	"name" (default), "company", "plan", "billingDatetime" or "createdDatetime"
    #  :orderByDirection   =>	"asc" (default) or "desc"
    #  :search             =>	Tcustomer name, company, email address and last four digits of credit card.
    #}    
    def get_customer_list(data = nil)
      do_request(:item => :customers, :action => :list, :data => data)
    end
    
    #https://cheddargetter.com/developers#single-customer
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    def get_customer(id_hash = { })
      do_request(:item => :customers, :action => :get, :id_hash => id_hash)
    end
    
    #https://cheddargetter.com/developers#add-customer
    #
    #data:
    #
    #{ 
    #  :code                 => required,
    #  :firstName            => required,
    #  :lastName             => required,
    #  :email                => required,
    #  :company              => not_required,
    #  :isVatExempt          => not_required,
    #  :vatNumber            => not_required,
    #  :notes                => not_required,
    #  :firstContactDatetime => not_required,
    #  :referer              => not_required,
    #  :campaignTerm         => not_required,
    #  :campaignName         => not_required,
    #  :campaignSource       => not_required,
    #  :campaignMedium       => not_required,
    #  :campaignContent      => not_required,
    #  :metaData => { #not_required
    #    :any_user_defined_value => not_required
    #  },
    #  :subscription => { #required
    #    :planCode        => required,
    #    :initialBillDate => not_required,
    #    :ccNumber        => required_if_not_free,
    #    :ccExpiration    => required_if_not_free,
    #    :ccCardCode      => required_if_not_free,
    #    :ccFirstName     => required_if_not_free,
    #    :ccLastName      => required_if_not_free,
    #    :ccCompany       => not_required,
    #    :ccCountry       => not_required,
    #    :ccAddress       => not_required,
    #    :ccCity          => not_required,
    #    :ccState         => not_required,
    #    :ccZip           => required_if_not_free
    #  },
    #  :charges => { #not required
    #    :user_defined => { 
    #      :chargeCode  => required_if_adding_a_charge,
    #      :quantity    => required_if_adding_a_charge,
    #      :eachAmount  => required_if_adding_a_charge,
    #      :description => not_required
    #    }
    #  },
    #  :items => { #not required
    #    :user_defined => { 
    #      :itemCode => required_if_setting_an_item,
    #      :quantity => required_if_setting_an_item
    #    }
    #  }
    #}
    #
    #Pass in the cookie info hash if you have been using the 
    #set_marketing_cookie method to track marketing metrics.
    #Info from the marketing cookie will be passed along to 
    #Cheddar Getter in the new_customer call.
    #
    #cookie_info (optional):
    #
    #{
    #  :cookies => required
    #  :cookie_name => not_required
    #}
    def new_customer(data = { }, cookie_info = nil)
      if cookie_info
        cookie_name = cookie_info[:cookie_name] || DEFAULT_COOKIE_NAME
        cookie_data = (YAML.load(cookie_info[:cookies][cookie_name] || "") rescue nil) || { }
        [:firstContactDatetime, :referer, :campaignTerm, :campaignName, 
         :campaignSource, :campaignMedium, :campaignContent].each do |key|
          data[key] ||= cookie_data[key] if cookie_data[key]
        end
      end
      do_request(:item => :customers, :action => :new, :data => data)
    end
    
    #https://cheddargetter.com/developers#update-customer-subscription
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    #
    #data:
    #
    #{ 
    #  :firstName            => not_required,
    #  :lastName             => not_required,
    #  :email                => not_required,
    #  :company              => not_required,
    #  :isVatExempt          => not_required,
    #  :vatNumber            => not_required,
    #  :notes                => not_required,
    #  :firstContactDatetime => not_required,
    #  :referer              => not_required,
    #  :campaignTerm         => not_required,
    #  :campaignName         => not_required,
    #  :campaignSource       => not_required,
    #  :campaignMedium       => not_required,
    #  :campaignContent      => not_required,
    #  :metaData => { #not_required
    #    :any_user_defined_value => not_required
    #  },
    #  :subscription => { #not_required
    #    :planCode        => not_required,
    #    :changeBillDate  => not_required,
    #    :ccNumber        => not_required_unless_plan_change_from_free_to_paid,
    #    :ccExpiration    => not_required_unless_plan_change_from_free_to_paid,
    #    :ccCardCode      => not_required_unless_plan_change_from_free_to_paid,
    #    :ccFirstName     => not_required_unless_plan_change_from_free_to_paid,
    #    :ccLastName      => not_required_unless_plan_change_from_free_to_paid,
    #    :ccCompany       => not_required,
    #    :ccCountry       => not_required,
    #    :ccAddress       => not_required,
    #    :ccCity          => not_required,
    #    :ccState         => not_required,
    #    :ccZip           => not_required_unless_plan_change_from_free_to_paid
    #  },
    #}
    def edit_customer(id_hash = { }, data = { })
      do_request(:item => :customers, :action => :edit, :id_hash => id_hash, :data => data)
    end
    
    #https://cheddargetter.com/developers#update-customer
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    #
    #data:
    #
    #{ 
    #  :firstName            => not_required,
    #  :lastName             => not_required,
    #  :email                => not_required,
    #  :company              => not_required,
    #  :notes                => not_required,
    #  :metaData => { #not_required
    #    :any_user_defined_value => not_required
    #  },
    #}
    def edit_customer_only(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "edit-customer", :id_hash => id_hash, :data => data)
    end
    
    #https://cheddargetter.com/developers#delete-customer
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    def delete_customer(id_hash = { })
      do_request(:item => :customers, :action => :delete, :id_hash => id_hash)
    end
    
    #https://cheddargetter.com/developers#delete-all-customers
    def delete_all_customers(time = Time.now.to_i)
      do_request(:item => :customers, :action => "delete-all/confirm/#{time}")
    end
    
    #https://cheddargetter.com/developers#update-subscription
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    #
    #data:
    #
    #{
    #  :planCode        => not_required,
    #  :changeBillDate  => not_required,
    #  :ccNumber        => not_required_unless_plan_change_from_free_to_paid,
    #  :ccExpiration    => not_required_unless_plan_change_from_free_to_paid,
    #  :ccCardCode      => not_required_unless_plan_change_from_free_to_paid,
    #  :ccFirstName     => not_required_unless_plan_change_from_free_to_paid,
    #  :ccLastName      => not_required_unless_plan_change_from_free_to_paid,
    #  :ccCompany       => not_required,
    #  :ccCountry       => not_required,
    #  :ccAddress       => not_required,
    #  :ccCity          => not_required,
    #  :ccState         => not_required,
    #  :ccZip           => not_required_unless_plan_change_from_free_to_paid
    #}
    def edit_subscription(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "edit-subscription", :id_hash => id_hash, :data => data)
    end
    
    #https://cheddargetter.com/developers#cancel-subscription
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    def cancel_subscription(id_hash = { })
      do_request(:item => :customers, :action => :cancel, :id_hash => id_hash)
    end
    
    #https://cheddargetter.com/developers#add-item-quantity
    #
    #id_hash: 
    #
    #{
    #  :code => Either code or id are required (this is the customer code)
    #  :id => Either code or id are required (this is the customer id)
    #  :item_code => Either item code or item id are required
    #  :item_id => Either item code or item id are required
    #}
    #
    #data: (not required)
    #
    #{ :quantity => treated_as_1_if_not_set }
    def add_item_quantity(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "add-item-quantity", :id_hash => id_hash, 
                 :data => data, :add_item_id => true)
    end
    
    #https://cheddargetter.com/developers#remove-item-quantity
    #
    #id_hash: 
    #
    #{
    #  :code => Either code or id are required (this is the customer code)
    #  :id => Either code or id are required (this is the customer id)
    #  :item_code => Either item code or item id are required
    #  :item_id => Either item code or item id are required
    #}
    #
    #data: (not required)
    #
    #{ :quantity => treated_as_1_if_not_set }
    def remove_item_quantity(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "remove-item-quantity", :id_hash => id_hash, 
                 :data => data, :add_item_id => true)
    end
    
    #https://cheddargetter.com/developers#set-item-quantity
    #
    #id_hash: 
    #
    #{
    #  :code => Either code or id are required (this is the customer code)
    #  :id => Either code or id are required (this is the customer id)
    #  :item_code => Either item code or item id are required
    #  :item_id => Either item code or item id are required
    #}
    #
    #data: { :quantity => required }
    def set_item_quantity(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "set-item-quantity", :id_hash => id_hash, 
                 :data => data, :add_item_id => true)
    end
    
    #https://cheddargetter.com/developers#add-charge
    #
    #id_hash: {:code => customer_code} OR {:id => customer_id}
    #
    #data:
    #
    #{
    #  :chargeCode  => required,
    #  :quantity    => required,
    #  :eachAmount  => required,
    #  :description => not_required
    #}
    def add_charge(id_hash = { }, data = { })
      do_request(:item => :customers, :action => "add-charge", :id_hash => id_hash, :data => data)
    end

     #https://cheddargetter.com/developers#delete-charge
     #
     #id_hash: {:code => customer_code} OR {:id => customer_id}
     #
     #data:
     #
     #{
     #  :chargeId  => required,
     #}    
     def delete_charge(id_hash = { }, data = { })
       do_request(:item => :customers, :action => "delete-charge", :id_hash => id_hash, :data => data)
     end

    # https://cheddargetter.com/developers#one-time-invoice 
    # 
    # id_hash: {:code => customer_code} OR {:id => customer_id}
    # 
    # data:
    # :charges =>
    # {"0" => {
    #   :chargeCode, 
    #   :quantity, 
    #   :eachAmount
    #   :description
    # },
    # {"1" => {
    #   :chargeCode, 
    #   :quantity, 
    #   :eachAmount
    #   :description
    # }
    # etc
    def add_one_time_invoice(id_hash = {}, data = {})
      do_request(:item => :invoices, :action => 'new', :id_hash => id_hash, :data => data)
    end    

    #http://support.cheddargetter.com/faqs/marketing-metrics/marketing-metrics
    #
    #Convenience wrapper of setcookie() for setting a persistent cookie 
    #containing marketing metrics compatible with CheddarGetter's marketing metrics tracking.
	  #Running this method on every request to your marketing site sets or refines the marketing 
    #cookie data over time.
    #If you are using this method, you can pass in the cookies to the new_customer call, 
    #which will automatically add the data to the customer record.  
    #
    #Sample usage for your controller:
    # 
    #  before_filter :update_cheddar_getter_cookie
    #  def update_cheddar_getter_cookie
    #    CheddarGetter::Client.set_marketing_cookie(:cookies => cookies, :request => request)
    #  end
    #
    #options:
    #
    #{
    #  :cookies     => required,
    #  :request     => required,
    #  :cookie_name => not_required (default 'CGMK'),
    #  :expires     => not_required (default 2 years),
    #  :path        => not_required (default '/'),
    #  :domain      => not_required (default nil),
    #  :secure      => not_required (default false),
    #  :httponly    => not_required (default false)
    #}
    def self.set_marketing_cookie(options = { })
      default_options = { 
        :cookie_name => DEFAULT_COOKIE_NAME,
        :expires => Time.now + 60*60*24*365*2,
        :path => '/',
        :domain => nil,
        :secure => false,
        :httponly => false
      }
      
      options = default_options.merge(options)
      cookies = options[:cookies]
      raise CheddarGetter::ClientException.new("The option :cookies is required") unless cookies
      request = options[:request]
      raise CheddarGetter::ClientException.new("The option :request is required") unless request
      
      utm_params = { 
        :utm_term     => :campaignTerm, 
        :utm_campaign => :campaignName, 
        :utm_source   => :campaignSource, 
        :utm_medium   => :campaignMedium, 
        :utm_content  => :campaignContent 
      }
      
      # get the existing cookie information, if any
      cookie_data = (YAML.load(cookies[options[:cookie_name]] || "") rescue nil)
      cookie_data = nil unless cookie_data.kind_of?(Hash)

      # no cookie yet -- set the first contact date and referer in the cookie
      # (only first request)
      if !cookie_data
        # when did this lead first find us? (right now!)
        # we'll use this to determine the customer "vintage"
        cookie_data = { :firstContactDatetime => Time.now.strftime("%Y-%m-%dT%H:%M:%S%z") }

        # if there's a __utma cookie, we can get a more accurate time
        # which helps us get better data from visitors who first found us
        # before we started setting our own cookie
        if cookies['__utma']
          domain_hash, visitor_id, initial_visit, previous_visit, current_visit, visit_counter =
            cookies['__utma'].split('.')
        
          initial_visit = initial_visit.to_i
          if initial_visit != 0
            cookie_data[:firstContactDatetime] = Time.at(initial_visit).strftime("%Y-%m-%dT%H:%M:%S%z") 
          end
        end

        #set the raw referer (defaults to 'direct')
        cookie_data[:referer] = 'direct'
        cookie_data[:referer] = request.env['HTTP_REFERER'] unless request.env['HTTP_REFERER'].blank?

        # if there's some utm vars
        # When tagging your inbound links for google analytics 
        #   http://www.google.com/support/analytics/bin/answer.py?answer=55518
        # our cookie will also benenfit by the added params
        utm_params.each { |k, v| cookie_data[v] = request.params[k] unless request.params[k].blank? }
        
        cookies[options[:cookie_name]] = { 
          :value => cookie_data.to_yaml,
          :path => options[:path],
          :domain => options[:domain],
          :expires => options[:expires],
          :secure => options[:secure],
          :httponly => options[:httponly]
        }

      # cookie is already set but maybe we can refine it with __utmz data
		  # (second and subsequent requests)
      elsif cookies['__utmz']
        return if cookie_data.size >= 3 #already has enough info

        domain_hash, timestamp, session_number, campaign_number, campaign_data =
          cookies['__utmz'].split('.')

        return if campaign_data.blank?
        campaign_data = (Hash[*campaign_data.split(/\||=/)] rescue { })

        # see if it's a google adwords lead 
        # in this case, we only get the keyword
        if ! campaign_data["utmgclid"].blank? 
          cookie_data[:campaignSource] = 'google';
          cookie_data[:campaignMedium] = 'ppc';
          cookie_data[:campaignTerm]   = campaign_data["utmctr"] unless campaign_data["utmctr"].blank?
        else
          cookieData[:campaignSource]  = campaign_data["utmcsr"] unless campaign_data["utmcsr"].blank?
          cookieData[:campaignName]    = campaign_data["utmccn"] unless campaign_data["utmccn"].blank?
          cookieData[:campaignMedium]  = campaign_data["utmcmd"] unless campaign_data["utmcmd"].blank?
          cookieData[:campaignTerm]    = campaign_data["utmctr"] unless campaign_data["utmctr"].blank?
          cookieData[:campaignContent] = campaign_data["utmcct"] unless campaign_data["utmcct"].blank?
        end
        
        cookies[options[:cookie_name]] = { 
          :value => cookie_data.to_yaml,
          :path => options[:path],
          :domain => options[:domain],
          :expires => options[:expires],
          :secure => options[:secure],
          :httponly => options[:httponly]
        }
      end
    end
    
    
    private
    def get_identifier_string(type, id_hash)
      code = type ? "#{type}_code".to_sym : :code
      id = type ? "#{type}_id".to_sym : :id
      
      if id_hash[code]
        str = type ? "#{type}Code" : "code"
        "/#{str}/#{CGI.escape(id_hash[code].to_s)}"
      elsif id_hash[id]
        str = type ? "#{type}Id" : "id"
        "/#{str}/#{CGI.escape(id_hash[id].to_s)}"
      else
        raise CheddarGetter::ClientException.new("Either a :#{code} or :#{id} is required")
      end
    end
    
    def do_request(options)
      data = options[:data]
      deep_fix_request_data!(data)
      
      path = "/xml/#{options[:item]}/#{options[:action]}"
      path += get_identifier_string(nil, options[:id_hash]) if options[:id_hash]
      path += get_identifier_string("item", options[:id_hash]) if options[:add_item_id]
      path += if product_code
                "/productCode/#{CGI.escape(product_code.to_s)}"
              elsif product_id
                "/productId/#{CGI.escape(product_id.to_s)}"
              else
                raise CheddarGetter::ClientException.new("A product code or id is required to make requests.")
              end
      
      response = if data
                   CheddarGetter::Client.post(path, :body => data, :basic_auth => { 
                                                :username => self.username, 
                                                :password => self.password
                                              })
                 else
                   CheddarGetter::Client.get(path, :basic_auth => { 
                                               :username => self.username, 
                                               :password => self.password
                                             }) 
                 end
      
      CheddarGetter::Response.new(response)
    end
    
    FIX_UP_KEYS = { 
      :ccExpiration => :month_year,
      :isVatExempt => :boolean,
      :initialBillDate => :year_month_day,
      :createdAfterDate => :year_month_day,
      :createdBeforeDate => :year_month_day,
      :canceledAfterDate => :year_month_day,
      :canceledBeforeDate => :year_month_day,
      :firstContactDatetime => :datetime,
      :changeBillDate => :datetime
    }
    
    DEFAULT_COOKIE_NAME = 'CGMK'
    
    def deep_fix_request_data!(data)
      if data.is_a?(Array)
        data.each do |v|
          deep_fix_request_data!(v) 
        end
      elsif data.is_a?(Hash)
        data.each do |k, v|
          deep_fix_request_data!(v)
          type = FIX_UP_KEYS[k]
          if type
            data[k] = case type
                        when :month_year then v.respond_to?(:strftime) ? v.strftime("%m/%Y") : v
                        when :boolean then v ? "1" : "0"
                        when :year_month_day then v.respond_to?(:strftime) ? v.strftime("%Y-%m-%d") : v
                        when :datetime then v.respond_to?(:strftime) ? v.strftime("%Y-%m-%dT%H:%M:%S%z") : v
                        else v
                        end
          end
        end
      end
    end
    
  end
end

