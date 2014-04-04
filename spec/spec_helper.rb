require 'rgigya' # and any other gems you need
require 'helpers.rb'
RSpec.configure do |config|
  # some (optional) config here
  config.include Helpers

  # To verify Values
  # GIGYA_API_KEY = "<add api key here>"
  # GIGYA_API_SECRET = "<add api secret here>"

end
