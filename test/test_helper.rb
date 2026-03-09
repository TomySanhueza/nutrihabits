ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "etc"

module ActiveSupport
  class TestCase
    # PostgreSQL validation in this project is stable when tests run serially by default.
    # Opt in to process parallelization only when the runner/environment is known-safe.
    if ENV["PARALLELIZE_TESTS"] == "1"
      parallelize(
        workers: Integer(ENV.fetch("PARALLEL_WORKERS", Etc.nprocessors.to_s)),
        threshold: Integer(ENV.fetch("PARALLEL_THRESHOLD", "50"))
      )
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
