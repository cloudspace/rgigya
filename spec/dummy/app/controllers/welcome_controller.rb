require 'Gigya'

class WelcomeController < ApplicationController  
  
  # GET /
  # GET /welcome.html
  # GET /welcome.xml                                                
  # GET /welcome.json                                       HTML and AJAX
  #-----------------------------------------------------------------------
  def index
    if(params)
      @user_info = Gigya.socialize_getUserInfo({
        'UID' => params['UID']
      });
    end
  end
  
end
