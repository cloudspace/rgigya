module Helpers
  def get_uid
    response = RGigya.socialize_notifyLogin({
      :siteUID => '1'
    })
    return response['UID']
  end
end