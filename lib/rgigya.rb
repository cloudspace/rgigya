require 'json'
require 'httparty'
require 'cgi' unless Object.const_defined?("CGI")
require File.dirname(__FILE__)+"/rgigya/base.rb"
require File.dirname(__FILE__)+"/rgigya/sig_utils.rb"
