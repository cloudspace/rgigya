#
# Quick sdk for the gigya api
#
# You can reference api calls at http://developers.gigya.com/037_API_reference
#
# Example call
# RGigya.socialize_setStatus(:uid => @user.id,:status => 'hello')
#
# We split the method name by the underscore and then map 
# the first token to the correct url
# The example above calls the url https://socialize.gigya.com/socialize.setStatus
#
# @author Scott Sampson
# @author Michael Orr


#
# Constants to be used for the gigya key and secret.  
# These should be commented out and set in your environments for your rails project.
# Uncomment below for testing without rails
#
# RGigya.config({
#   :api_key => "12345",
#   :api_secret => "12345,
#   :use_ssl => false,
#   :domain => "us1"
# })



module RGigya

  # List of Available API methods
  @@valid_methods = [:socialize, :gm, :comments, :accounts, :reports, :chat, :ds]
  
  # Used to compare when we get a bad signature, mainly for debugging but helpful
  @@base_signature_string = ""
  @@signature = ""
      
  #
  # Custom Exceptions so we know it came from the library
  # When in use please namespace them appropriately RGigya::ResponseError for readability
  #
  exceptions = %w[UIDParamIsNil SiteUIDParamIsNil ResponseError BadParamsOrMethodName ErrorCodeReturned MissingApiKey MissingApiSecret InvalidLoginIdOrPassword PasswordCannotBeTheSame]
  exceptions.each { |e| const_set(e, Class.new(StandardError)) }
  RGigya::JSONParseError = Class.new(JSON::ParserError)
  
  class << self
    
    
    #
    # Sets the config data to be used in the api call
    #
    # @param [Hash] config_dat Hash of key value pairs passed to the gigya api
    #
    # @author Scott Sampson
    def config(config_data)
      @@api_key = config_data[:api_key]
      @@api_secret = config_data[:api_secret]
      @@use_ssl = config_data[:use_ssl] || false
      @@domain = config_data[:domain] || "us1"
      
      verify_config_data
    end
    
    # Validates that we have required config data
    #
    # @author Scott Sampson
    def verify_config_data
      if(!defined?(@@api_key)) 
        raise RGigya::MissingApiKey, "Please provide a Gigya api key in the config data"
      end
      if(!defined?(@@api_secret)) 
        raise RGigya::MissingApiSecret, "Please provide a Gigya api secret in the config data"
      end
    end
    
    #
    # Adds the required params for all api calls
    # 
    def required_parameters
      params =  "apiKey=#{CGI.escape(@@api_key)}"
      params += "&secret=#{CGI.escape(@@api_secret)}"
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
    def build_url(method, http_method, options = {})
      if options && options.has_key?(:uid) && options[:uid].nil?
        raise RGigya::UIDParamIsNil, ""
      end
      
      if options && options.has_key?(:siteUID) && options[:siteUID].nil?
        raise RGigya::SiteUIDParamIsNil, ""
      end

      method_type,method_name = method.split(".")
      if(http_method == "GET") 
        url = "https://#{method_type}.#{@@domain}.gigya.com/#{method}?#{required_parameters}"
        if(options)
          options.each do |key,value|
            url += "&#{key}=#{CGI.escape(value.to_s)}"
          end
        end
      else 
        url = "http://#{method_type}.#{@@domain}.gigya.com/#{method}"
      end
      url
    end
    
    #
    # sends the https call to gigya and parses the result
    # This is used for https get requests
    # 
    # @param [String] method The method name to be called in the gigya api
    # @param [Hash] options Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the api results in key/value format
    #
    # @author Scott Sampson
    def parse_results_secure(method,options)
      # options = {} if options.is_a?(String) && options.blank?
      begin
        response = HTTParty.get(build_url(method, "GET", options),{:timeout => 10})
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
    # Orders the params hash for the signature
    # Changes boolean values to their string equivalent
    # 
    # @param [Hash] h Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the params being passed to the gigya api with their keys in alpha order
    #
    # @author Scott Sampson
    def prepare_for_signature(h)
      ordered_hash = {} #insert order with hash is preserved since ruby 1.9.2
      h = h.inject({}){|p,(k,v)| p[k.to_sym] = v; p}
      h.keys.sort.each do |key|
        value = h[key]
        if(!!value == value) #duck typeing.......quack
          ordered_hash[key] = value.to_s
        else
          ordered_hash[key] = value
        end
      end
      return ordered_hash
    end
    
    
    #
    # Adds Timestamp, nonce and signatures to the params hash
    # 
    # @param [String] request_uri the url we are using for the api call
    # @param [Hash] params Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the params being passed to the gigya api
    # with timestamp, nonce and signature added
    #
    # @author Scott Sampson
    def params_with_signature(request_uri,params)
        timestamp = Time.now.utc.strftime("%s")
        nonce  = SigUtils::current_time_in_milliseconds()
        
        params = {} if params.nil?
        
        params[:format] = "json"
        params[:timestamp] = timestamp
        params[:nonce] = nonce
        params[:apiKey] = @@api_key
        
        normalized_url = CGI.escape(request_uri)
        
        query_string = CGI.escape(prepare_for_signature(params).to_query)
                        
        # signature_string = SECRET + request_uri + timestamp
        @@base_signature_string = "POST&#{normalized_url}&#{query_string}"
        
        digest = SigUtils::calculate_signature(@@base_signature_string,@@api_secret)
        @@signature = digest.to_s
        params[:sig] = @@signature
        return params
    end
    
    #
    # sends the http call with signature to gigya and parses the result
    # This is for http post requests
    # 
    # @param [String] method The method name to be called in the gigya api
    # @param [Hash] options Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the api results in key/value format
    #
    # @author Scott Sampson
    
    def parse_results_with_signature(method, options)
      request_uri = build_url(method, "POST", options)
      begin        
        response = HTTParty.post(request_uri, { :body => params_with_signature(request_uri,options) })
      rescue URI::InvalidURIError
        # need to treat this like method missing
        return false
      rescue SocketError,Timeout::Error => e
        raise RGigya::ResponseError, e.message
      end
      
      
      begin
        doc = JSON(response.body)
      rescue JSON::ParserError => e
        raise RGigya::JSONParseError, e.message
      end
      doc
    end
    
    
    #
    # sends the api call to gigya and parses the result with appropriate method
    # 
    # @param [String] method The method name to be called in the gigya api
    # @param [Hash] options Hash of key value pairs passed to the gigya api
    #
    # @return [Hash] hash of the api results in key/value format
    #
    # @author Scott Sampson
    def parse_results(method, options = {})
      verify_config_data
      return @@use_ssl ? parse_results_secure(method,options) : parse_results_with_signature(method,options)
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
    # @author Scott Sampson, Mark Rickert
    def check_for_errors(results)
      case results['errorCode'].to_s
        when '0'
          return results
        when '400124'
          #Limit Reached error - don't fail so bad
        when '400002'
          raise RGigya::BadParamsOrMethodName, results['errorDetails']
        when '403003'
          log_error(results)
          log("Rgigya base_signature_string = #{@@base_signature_string}\n\n")
          log("Gigya base_signature_string = #{results['baseString']}\n\n\n")
          log("Rgigya signature = #{@@signature}\n\n")
          log("Gigya signature = #{results['expectedSignature']}\n\n")
        when '400006'
          log_error(results)
          raise RGigya::PasswordCannotBeTheSame, "returned Error code #{results['errorCode']}: #{results['errorMessage']}"
        when '403042'
          log_error(results)
          raise RGigya::InvalidLoginIdOrPassword, "returned Error code #{results['errorCode']}: #{results['errorMessage']}"
        else
          log_error(results)
          raise RGigya::ErrorCodeReturned, "returned Error code #{results['errorCode']}: #{results['errorMessage']}"
      end
    end

    ##
    # Helper method to log errors so these strings aren't duplicated in the method above.
    #
    # @param [Hash] results The results to log
    #
    # @author Mark Rickert
    def log_error(results)
      log("RGigya returned Error code #{results['errorCode']}.\n\nError Message: #{results['errorMessage']}\n\nError Details: #{results['errorDetails']}")
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
      method_type,method_name = method.split(".")
      
      if(@@valid_methods.include?(method_type.to_sym))
        results = parse_results(method, args.first)
      else 
        results = false
      end
      
      if results
        return check_for_errors(results)
      else 
        super
      end
    end
    
    
    ##
    # Override respond_to? We can't really give an accurate return here
    # I am only allowing those methods that start with the methods listed in the @@valid_methods array
    #
    # @param [Symbol] sym The method symbol
    # @param [Boolean] include_private Whether you want to include private or not. 
    #
    # @author Scott Sampson
    def respond_to?(sym, include_private = false)
      method = sym.to_s.gsub("_",".")
      method_type,method_name = method.split(".")
      return @@valid_methods.include?(method_type.to_sym)
    end
    
    
        
    #
    # Custom log method, if we are in rails we should log any errors for debugging purposes
    #
    # @param [String] log_str string to log
    #
    # @author Scott Sampson
    def log(log_str)
      if Object.const_defined?('Rails')
        Rails.logger.info(log_str)
      else
        puts log_str
      end
    end
  end
end
