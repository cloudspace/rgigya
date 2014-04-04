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

  # Note:  I stub everything here including the signature so this test really isn't valid
  # But, it explains how it works
  it "should verify friends signature after successful api call" do
    RGigya.stub(:socialize_getFriendsInfo) do |url,options|
      # this method is in helpers.rb
      sample_frends_json_data
    end

    response = RGigya.socialize_getFriendsInfo({
      :uid => '1',
      :signIDs => true
    })

    friend = response['friends'].first

    RGigya::SigUtils::validate_friend_signature("1", friend['signatureTimestamp'], friend['UID'], friend['friendshipSignature']).should be_true
  end

  # Not much of test here because the signature always change
  # Lets just run it to make sure its not throwing any errors
  it "should return the value for the dynamic session cookie" do
    two_hours_from_now = (Time.now + (60*60*2)).utc.strftime("%s").to_i
    RGigya::SigUtils::get_dynamic_session_signature("111111111", two_hours_from_now).should_not == ""
  end
end
