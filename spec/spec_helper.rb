# frozen_string_literal: true

require 'aruba/rspec'
require 'simplecov'

SimpleCov.start 'rbexec_rspec' unless SimpleCov.running

require 'support/helpers'
require 'support/shared_context'
require 'support/shared_examples'

RSpec.configure do |config|
  config.add_setting :fixtures_path, :default => File.expand_path('../fixtures', __FILE__)

  config.color      = true
  config.formatter  = 'documentation'
  config.order      = 'rand'

  config.include Helpers
end
