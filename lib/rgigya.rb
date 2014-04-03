require 'json'
require 'httparty'
require 'cgi' unless Object.const_defined?("CGI")
require File.dirname(__FILE__)+"/rgigya/base.rb"
require File.dirname(__FILE__)+"/rgigya/sig_utils.rb"
require 'active_support/core_ext/object/to_query' # for Hash#to_query (included with rails by default)
