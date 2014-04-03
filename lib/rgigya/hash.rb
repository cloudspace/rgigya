#
# Mixin for ruby's Hash class
#
#
# @author Scott Sampson
# @author Michael Orr

class Hash


  # returns a query string
  #
  # @return [String] concated string of key value pairs in the hash
  #
  # @author Scott Sampson
  def to_query
    self.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v)}"}.join("&")
  end
end
