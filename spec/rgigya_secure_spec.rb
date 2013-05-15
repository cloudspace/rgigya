require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/rgigya_shared_examples.rb')

describe "RGigyaSecure" do
  before :each do
    RGigya.config({
      :api_key => GIGYA_API_KEY,
      :api_secret => GIGYA_API_SECRET,
      :use_ssl => true,
      :domain => "us1"
    })
    @protocol = "https"
    @method = "GET"
  end
  
  
  it_behaves_like RGigya
end
