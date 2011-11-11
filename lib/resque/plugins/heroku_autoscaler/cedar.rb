require 'resque/plugins/resque_heroku_autoscaler'

module Resque
  module Plugins
    module HerokuAutoscaler
      module Cedar
        
        def set_workers(number_of_workers)
          if number_of_workers != current_workers
            heroku_client.ps_scale(Resque::Plugins::HerokuAutoscaler::Config.heroku_app, :type => 'worker', :qty => number_of_workers)
          end
        end
        
        def current_workers
          heroku_client.ps(Resque::Plugins::HerokuAutoscaler::Config.heroku_app).count { |p| p["process"] =~ /worker\.\d?/ }
        end
        
      end
    end
  end
end
