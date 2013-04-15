require 'json'
require 'httparty'
require 'CGI'

#
# Quick sdk for the gigya api
#
# You can reference api calls at http://developers.gigya.com/037_API_reference
#
# Example call
# RGigya.socialize_setStatus(:uid => @user.id,:status => 'hello')
#
# We split the method name by the underscore and then map 
# the first token to the correct url using the @@urls class variable
# The example above calls the url https://socialize.gigya.com/socialize.setStatus
#
# @author Scott Sampson


#
# Constants to be used for the gigya key and secret.  
# These should be commented out and set in your environments for the project.
# Uncomment below for testing without rails
#
# GIGYA_API_KEY = "12345"
# GIGYA_API_SECRET = "12345"


class RGigya
  
  # Mapping to different urls based on api groupings
  @@urls = {
    socialize: "https://socialize-api.gigya.com",
    gm: "https://gm.gigya.com",
    comments: "https://comments.gigya.com"
  }
  
  #
  # Custom Exceptions so we know it came from the library
  # When in use please namespace them appropriately RGigya::ResponseError for readability
  #
  exceptions = %w[ UIDParamIsNil SiteUIDParamIsNil ResponseError BadParamsOrMethodName ErrorCodeReturned  ]  
  exceptions.each { |e| const_set(e, Class.new(StandardError)) }
  RGigya::JSONParseError = Class.new(JSON::ParserError)
  
  class << self
    
    #
    # Adds the required params for all api calls
    # 
    def required_parameters
      params =  "apiKey=#{CGI.escape(GIGYA_API_KEY)}"
      params += "&secret=#{CGI.escape(GIGYA_API_SECRET)}"
      params += "&format=json"
    end
    
    #
    # builds the url to be sent to the api
    #
    # @param [String] method The method name to be called in the gigya api
    # @param [Hash] options Hash of key value pairs passed to the gigya api
    #
    # @return [String] the full url to be sent to the api
    #
    # @author Scott Sampson
    def build_url(method, options = {})
      # options = {} if options.blank?
      if options && options.has_key?(:uid) && options[:uid].nil?
        raise RGigya::UIDParamIsNil, ""
      end
      
      if options && options.has_key?(:siteUID) && options[:siteUID].nil?
        raise RGigya::SiteUIDParamIsNil, ""
      end

      method_type,method_name = method.split(".")
      url = "#{@@urls[method_type.to_sym]}/#{method}?#{required_parameters}"
      if(options)
        options.each do |key,value|
          url += "&#{key}=#{CGI.escape(value.to_s)}"
        end
      end
      url
    end
    
    #
    # sends the https call to gigya and parses the result
    # 
    # @param [String] method The method name to be called in the gigya api
    # @param [Hash] options Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the api results in key/value format
    #
    # @author Scott Sampson
    def parse_results(method, options = {})
      # options = {} if options.is_a?(String) && options.blank?
      begin
        response = HTTParty.get(build_url(method, options),{:timeout => 10})
      # rescue RGigya::ResponseError, RGigya::SiteUIDParamIsNil, RGigya::UIDParamIsNil => e 
      # rescue RGigya::ResponseError => e 
      rescue SocketError,Timeout::Error => e 
        raise RGigya::ResponseError, e.message
      end
      return false if response.nil? || response.body == "Bad Request"

      begin
        doc = JSON(response.body)
      rescue JSON::ParserError => e
        raise RGigya::JSONParseError, e.message
      end
      doc
    end
    
    #
    # Error handling of the results
    # 
    # @param [String]  The method name to be called in the gigya api
    # @param [Hash] results Hash of key value pairs returned by the results
    #
    # @return [String] hash of a successful api call
    # 
    # TODO:  Shouldn't fail so hard.  If there is a temporary connectivity problem we should fail more gracefully.
    # You can find a list of response codes at http://developers.gigya.com/037_API_reference/zz_Response_Codes_and_Errors
    #
    # @author Scott Sampson
    def check_for_errors(results)
      case results['errorCode'].to_s
        when '0'
          return results
        when '400124'
          #Limit Reached error - don't fail so bad
        when '400002'
          raise RGigya::BadParamsOrMethodNames
        else 
          log("RGigya returned Error code #{results['errorCode']}.\n\nError Message: #{results['errorMessage']}\n\nError Details: #{results['errorDetails']}")
          raise RGigya::ErrorCodeReturned, "returned Error code #{results['errorCode']}: #{results['errorMessage']}"
      end
    end
    
    ##
    # Override method_missing so we don't have to write all the dang methods
    #
    # @param [Symbol] sym The method symbol
    # @param [*Array] args The splatted array of method arguments passed in
    #
    # @author Scott Sampson
    def method_missing(sym, *args)
      method = sym.to_s.gsub("_",".")
      results = parse_results(method, args.first)
      if results
        return check_for_errors(results)
      else 
        super
      end
    end
        
    ##
    # Custom log method, if we are in rails we should log any errors for debugging purposes
    #
    # @param [String] log_str string to log
    #
    # @author Scott Sampson
    def log(log_str)
      if Object.const_defined?('Rails')
        Rails.logger.info(log_str)
      end
    end
  end
end
