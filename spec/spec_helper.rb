require 'rspec'
require 'heroku'
require 'resque'
require 'timecop'
require 'resque/plugins/heroku_autoscaler/config'
require 'resque/plugins/resque_heroku_autoscaler'
require 'resque/plugins/heroku_autoscaler/cedar'

RSpec.configure do |config|
  config.mock_with :rr
end