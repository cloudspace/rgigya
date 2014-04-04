#
# Utility class to help with signatures when sending api calls to gigya
#
#
# @author Scott Sampson
# @author Michael Orr

#if you think about it as a namespace the include RGigya below doesn't seem weird at all
module RGigya

  class SigUtils
    include RGigya

    class << self

      # validates the signature from the api calls having to do with authentication
      # http://developers.gigya.com/010_Developer_Guide/87_Security#Validate_the_UID_Signature_in_the_Social_Login_Process
      #
      # @param [String] uid The id for the user who's friends you are getting
      # @param [String] timestamp The signatureTimestamp passed along with api call
      # @param [String] signature the UIDSignature we are verifying against
      #
      # @return [Boolean] true or false on whether the signature is valid
      #
      # @author Scott Sampson
  	  def validate_user_signature(uid, timestamp, signature)
  	    base = "#{timestamp}_#{uid}"
  	  	expected_signature = calculate_signature(base, @@api_secret)
    		return expected_signature == signature
  	  end

	    # validates the signature from the api calls having to do with friends
      # http://developers.gigya.com/010_Developer_Guide/87_Security#Validate_Friendship_Signatures_when_required
      #
      #
      # @param [String] uid The id for the user who's friends you are getting
      # @param [String] timestamp The signatureTimestamp passed along with each friend to verify the signature
      # @param [String] friend_uid gigya's user_id for the friend
      # @param [String] signature the friendshipSignature we are verifying against
      #
      # @return [Boolean] true or false on whether the signature is valid
      #
      # @author Scott Sampson
  	  def validate_friend_signature(uid, timestamp, friend_uid, signature)
    		base = "#{timestamp}_#{friend_uid}_#{uid}"
    		expected_signature = calculate_signature(base, @@api_secret)
    		return expected_signature == signature
  		end

      # generates the value for the session expiration cookie
      # http://developers.gigya.com/010_Developer_Guide/87_Security#Defining_a_Session_Expiration_Cookie
      #
      # You want to use this if you want to terminate a session in the future
      #
      # @param [String] glt_cookie The login token received from Gigya after successful Login.
      #     Gigya stores the token in a cookie named: "glt_" + <Your API Key>
      # @param [Integer] timeout_in_seconds The expiration time in seconds since Jan. 1st 1970 and in GMT/UTC timezone.
      #
      # @return [String] value you want to set in the cookie
      #
      # @author Scott Sampson
  	  def get_dynamic_session_signature(glt_cookie, timeout_in_seconds)
    		expiration_time_unix_ms = (current_time_in_milliseconds().to_i/1000) + timeout_in_seconds
        expiration_time_unix = expiration_time_unix_ms.floor.to_s
    		unsigned_expiration = "#{glt_cookie}_#{expiration_time_unix}"
    		signed_expiration = calculate_signature(unsigned_expiration,@@api_secret)
    		return "#{expiration_time_unix}_#{signed_expiration}"
  	  end

  	  # Returns the current utc time in milliseconds
      #
      # @return [String] current time in milliseconds
      #
      # @author Scott Sampson
  	  def current_time_in_milliseconds()
        return DateTime.now.strftime("%Q")
    	end

	    # Calulates the signature to be passed with the api calls
      #
      # @param [Strsing] base string that we are basing the signature off of
      # @param [String] key The key we are using the encode the signature
      #
      # @return [String] value of the signature
      #
      # @author Scott Sampson
      def calculate_signature(base,key)
        base = base.encode('UTF-8')
        raw = OpenSSL::HMAC.digest('sha1',Base64.decode64(key), base)
    		return Base64.encode64(raw).chomp.gsub(/\n/,'')
    	end
    end
  end
end
