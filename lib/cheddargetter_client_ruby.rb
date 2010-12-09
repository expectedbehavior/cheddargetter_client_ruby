require 'httparty'
require 'CGI' unless Object.const_defined?("CGI")

module CheddarGetter
  autoload :Client, "cheddar_getter/client"
  autoload :ClientException, "cheddar_getter/client_exception"
  autoload :Response, "cheddar_getter/response"
  autoload :ResponseException, "cheddar_getter/response_exception"
end
