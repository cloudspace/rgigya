# 
# 
# Check out the development evironment file on where to set the Gigya api key and secret.
# 
#

class WelcomeController < ApplicationController  
  
  # GET /
  # GET /welcome.html
  # GET /welcome.xml                                                
  # GET /welcome.json                                       HTML and AJAX
  #-----------------------------------------------------------------------
  def index
    if(params.has_key?('UID'))
      @user_info = RGigya.socialize_getUserInfo({
        'UID' => params['UID']
      });
    end
  end
  
end
