require 'rgigya' # and any other gems you need
require 'helpers.rb'
RSpec.configure do |config|
  # some (optional) config here
  config.include Helpers
  
  
  # these need to be filled out for tests to work
  GIGYA_API_KEY = ""
  GIGYA_API_SECRET = ""
  
end