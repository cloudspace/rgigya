module Helpers
  def get_uid
    response = RGigya.socialize_notifyLogin({
      :siteUID => '1'
    })
    return response['UID']
  end

  def sample_frends_json_data
    return JSON('{
      "friends": [{
        "UID": "00",
        "isSiteUser": false,
        "isSiteUID": false,
        "identities": [{
          "provider": "facebook",
          "providerUID": "00000",
          "isLoginIdentity": false,
          "nickname": "Baba",
          "photoURL": "http://profile.ak.fbcdn.net/hprofile-ak-snc4/00.jpg",
          "thumbnailURL": "http://profile.ak.fbcdn.net/hprofile-ak-snc4/00.jpg"}],
        "nickname": "Baba",
        "photoURL": "http://profile.ak.fbcdn.net/hprofile-ak-snc4/00.jpg",
        "thumbnailURL": "http://profile.ak.fbcdn.net/hprofile-ak-snc4/00.jpg",
        "signatureTimestamp": "11111111111",
        "friendshipSignature": "kfwFFiXqP+NySU79E+CZY0Pu1Mc="
      }],
      "statusCode": 200,
      "errorCode": 0,
      "statusReason": "OK",
      "callId": "e2b7c39de36541b4940087d66d4c1d77"
    }')
  end
end
