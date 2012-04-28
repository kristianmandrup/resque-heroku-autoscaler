require 'resque/plugins/heroku_autoscaler/config'
require 'resque/plugins/heroku_autoscaler/cedar'
require 'heroku'

module Resque
  module Plugins
    module HerokuAutoscaler
      def self.included(klass)
        # do something ti figure out which stack you're on
        # heroku_client.respond_to?(:set_workers) 
        # klass.extend Reque......::Cedar
        klass.extend(Cedar)
      end
      
      @@heroku_client = nil

      def after_enqueue_scale_workers_up(*args)
        unless Resque::Plugins::HerokuAutoscaler::Config.scaling_disabled?
          scale
        end
      end

      def after_perform_scale_workers(*args)
        calculate_and_set_workers
      end

      def on_failure_scale_workers(*args)
        calculate_and_set_workers
      end

      def set_workers(number_of_workers)
        if number_of_workers != current_workers
          heroku_client.set_workers(Resque::Plugins::HerokuAutoscaler::Config.heroku_app, number_of_workers)
        end
      end

      def current_workers
        heroku_client.info(Resque::Plugins::HerokuAutoscaler::Config.heroku_app)[:workers].to_i
      end

      def heroku_client
        @@heroku_client || @@heroku_client = Heroku::Client.new(Resque::Plugins::HerokuAutoscaler::Config.heroku_user,
                                                                Resque::Plugins::HerokuAutoscaler::Config.heroku_pass)
      end

      def self.config
        yield Resque::Plugins::HerokuAutoscaler::Config
      end

      def calculate_and_set_workers
        unless Resque::Plugins::HerokuAutoscaler::Config.scaling_disabled?
          wait_for_task_or_scale
          if time_to_scale?
            scale
          end
        end
      end

      private

      def scale
        new_count = Resque::Plugins::HerokuAutoscaler::Config.new_worker_count(Resque.info[:pending])
        set_workers(new_count) if new_count == 0 || new_count > current_workers
        Resque.redis.set('last_scaled', Time.now)
        exit if new_count == 0
      end

      def wait_for_task_or_scale
        until Resque.info[:pending] > 0 || time_to_scale?
          Kernel.sleep(0.5)
        end
      end

      def time_to_scale?
        last_scaled = Resque.redis.get('last_scaled')
        return true unless last_scaled
        (Time.now - Time.parse(last_scaled)) >=  Resque::Plugins::HerokuAutoscaler::Config.wait_time
      end

      def log(message)
        if defined?(Rails)
          Rails.logger.info(message)
        else
          puts message
        end
      end
    end
  end
end
