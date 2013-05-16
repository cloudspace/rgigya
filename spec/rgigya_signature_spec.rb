require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/rgigya_shared_examples.rb')

describe "RGigyaSignature" do
  before :each do
    RGigya.config({
      :api_key => GIGYA_API_KEY,
      :api_secret => GIGYA_API_SECRET,
      :use_ssl => false,
      :domain => "us1"
    })
    @protocol = "http"
    @method = "POST"
  end
  
  
  it_behaves_like RGigya
  
  it "should verify signature after successful login" do
    userInfo = {
      'nickname' => 'Gigems', 
      'email' => 'ralph@cloudspace.com',
      'firstName' => 'Ralph', 
      'lastName' => 'Masterson'
    }
    
    response = RGigya.socialize_notifyLogin({
      :siteUID => '1',
      :userInfo => userInfo.to_json
    })
    
    RGigya::SigUtils::validate_user_signature(response['UID'], response['signatureTimestamp'], response['UIDSignature']).should be_true
    
  end
  
  
  # it "should verify friends signature after successful api call" do
  #     userInfo = {
  #       'nickname' => 'Gigems', 
  #       'email' => 'ralph@cloudspace.com',
  #       'firstName' => 'Ralph', 
  #       'lastName' => 'Masterson'
  #     }
  #     
  #     response = RGigya.socialize_getFriendsInfo({
  #       :siteUID => '1',
  #       :userInfo => userInfo.to_json
  #     })
  #     
  #     RGigya::SigUtils::validate_user_signature(response['UID'], response['signatureTimestamp'], response['UIDSignature']).should be_true
  #     
  #   end
  
end
