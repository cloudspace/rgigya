
module RGigya

  class SigUtils
    
    
    class << self  
    
  	  def validate_user_signature(uid, timestamp, secret, signature) 
  	    base = "#{timestamp}_#{uid}"
  	  	expected_signature = calculate_signature(base, secret)
    		return expected_signature == signature
  	  end
	
  	  def validate_friend_signature(uid, timestamp, friend_uid, secret, signature)
    		base = "#{timestamp}_#{friend_uid}_#{uid}"
    		expected_signature = calculate_signature(base, secret)
    		return expected_signature == signature
  		end
		
  	  def get_dynamic_session_signature(glt_cookie, timeout_in_seconds, secret)
        # cookie format: 
        # <expiration time in unix time format>_BASE64(HMACSHA1(secret key, <login token>_<expiration time in unix time format>))
        
    		expiration_time_unix_ms = (current_time_in_milliseconds()/1000) + timeout_in_seconds
    		expiration_time_unix = Float.toString(expiration_time_unix_ms.floor)
    		unsigned_expiration = "#{glt_cookie}_#{expiration_time_unix}"
    		signed_expiration = calculate_signature(unsigned_expiration,secret) # sign the base string using the secret key
    		return "#{expiration_time_unix}_#{signed_expiration}" # define the cookie value
  	  end
  	  
  	  def current_time_in_milliseconds()
        return Time.now.to_f*1000.floor
    	end
	
      def calculate_signature(base,key)
    		base = base.encode('UTF-8')
        # Digest::SHA1.hexdigest 'foo'
        # return Base64.encode64((HMAC::SHA1.new('key') << 'base').digest).strip
    		return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), key, base))
    	end
  	  
    end
  end
end
