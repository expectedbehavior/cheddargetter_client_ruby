require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cheddargetter_client_ruby'

class Test::Unit::TestCase
end

CGEmail = "cheddargetter.rubygem.dev@gmail.com"
CGProductCode = 'RUBYGEM'
CG = CheddarGetter::Client.new(:product_code => CGProductCode,
                               :username => CGEmail,
                               :password => "t3stpassword")
