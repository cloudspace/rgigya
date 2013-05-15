class Hash
  def to_query(namespace = nil)
    self.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v)}"}.join("&")
  end
end