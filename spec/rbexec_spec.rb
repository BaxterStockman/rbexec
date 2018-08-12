# frozen_string_literal: true

require 'spec_helper'

require 'shell'

shells = %w[sh ash dash ksh mksh pdksh bash zsh]
if RUBY_VERSION >= '2.2.7'
  shells << ['bashcov', '--root', File.expand_path('../..', __FILE__), '--']
end

shells.each do |shell|
  describe "rbexec using `#{Array(shell).join(' ')}`", :type => :aruba do
    include_examples 'rbexec', shell
  end
end

describe 'RbExec' do
  include_context 'rbexec_setup'

  describe '#shell' do
    it 'defaults to using the system shell' do
      expect(rbexec.shell).to eq Shell.new.find_system_command('sh')
    end

    it 'uses /bin/sh if no system shell could be identified' do
      mock_shell = double('Shell')
      expect(mock_shell).to receive(:find_system_command).with('sh').and_raise(Shell::Error::CommandNotFound)
      expect(Shell).to receive(:new).and_return(mock_shell)
      expect(rbexec.shell).to eq '/bin/sh'
    end
  end

  describe '#shellopts' do
    it 'maps shell options ($-) to flags' do
      rbexec.shellopts = 'himBH'
      expect(rbexec.flags).to contain_exactly(*%w[-h -i -m -B -H])
    end
  end

  describe '#command' do
    it 'defaults to executing a shell' do
      rbexec.shell = '/bin/bash'
      rbexec.shellopts = 'himBH'
      expect(rbexec.command).to contain_exactly(rbexec.shell, *rbexec.flags)
    end
  end

  describe '#path' do
    it 'prepends GEM_HOME and GEM_ROOT binpaths to PATH' do
      path = rbexec.path.split(':')
      expect(path[0..1].map { |bin| File.dirname(bin) }).to contain_exactly(rbexec.gem_home, rbexec.gem_root)
    end

    it "moves the selected Ruby's bindir forward in the path" do
      rbexec.ruby = ruby
      ruby_bindir = File.dirname(rbexec.ruby)

      with_environment 'PATH' => [ENV['PATH'], ruby_bindir].join(':') do
        expect(rbexec.path.split(':').index(ruby_bindir)).to be <= ENV['PATH'].split(':').index(ruby_bindir)
      end
    end
  end

  describe '#to_h' do
    it 'represents the exported shell environment as a hash' do
      expect(rbexec.to_h).to be_a Hash
      expect(rbexec.to_h.keys).to include(*%w[GEM_HOME GEM_ROOT GEM_PATH RUBY_ENGINE RUBY_VERSION PATH])
    end
  end

  describe '#setenv!' do
    around do |ex|
      saved_env = ENV.to_hash
      ex.run
      ENV.replace(saved_env.to_hash)
    end

    it 'exports itself into the environment' do
      rbexec.setenv!
      rbexec.to_h.each do |k, v|
        expect(ENV[k]).to eq(v)
      end
    end

    context 'when the current EUID is 0' do
      it 'removes GEM_HOME and GEM_PATH from the environment' do
        allow(Process).to receive(:euid).and_return(0)
        rbexec.setenv!
        expect(ENV).not_to include('GEM_HOME', 'GEM_PATH')
      end
    end
  end
end
