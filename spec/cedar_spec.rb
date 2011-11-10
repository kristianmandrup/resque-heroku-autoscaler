require 'spec_helper'

class TestJob
  extend Resque::Plugins::HerokuAutoscaler::Cedar

  @queue = :test
end

describe Resque::Plugins::HerokuAutoscaler::Cedar do
  before do
    @fake_heroku_client = Object.new
    stub(@fake_heroku_client).set_workers
    stub(@fake_heroku_client).info { {:workers => 0} }
    stub(TestJob).log
    Resque::Plugins::HerokuAutoscaler::Config.reset
  end

  it "should be a valid Resque plugin" do
    lambda { Resque::Plugin.lint(Resque::Plugins::HerokuAutoscaler::Cedar) }.should_not raise_error
  end
end
