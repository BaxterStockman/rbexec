# frozen_string_literal: true

require 'rubygems'
require 'shellwords'

# :nocov:
begin
  require 'rbexec'
rescue LoadError
  abort 'Unable to load RbExec; have you run `rake rbexec:generate`?'
end
# :nocov:

RSpec.shared_context 'rbexec_setup' do
  let(:rbexec) { RbExec.new }
  let(:ruby) { ENV.fetch('RUBY', Gem.ruby) }

  # @todo :?
  before(:all) do
    ruby = ENV.fetch('RUBY', Gem.ruby)
    abort "Ruby should exist at #{ruby}, but I can't find it." unless File.executable?(ruby)
  end
end
