# frozen_string_literal: true

require 'rubygems'
require 'securerandom'
require 'set'

RSpec.shared_examples 'rbexec' do |shell|
  include_context 'rbexec_setup'

  let!(:fake_ruby)    { Pathname.new(RSpec.configuration.fixtures_path).join('bin/fake-ruby') }
  let!(:rubies_path)  { Pathname.new(Aruba.config.home_directory).join('.rubies') }
  let(:rbexec_rubies) { rubies_path.exist? ? rubies_path.children.map(&:to_s) : [] }

  before(:all) do
    shell = Array(shell)
    skip "#{shell} is not installed" unless which(shell.first)
  end

  around(:each, :mock_rubies => true) do |example|
    abort 'you must define :ruby_aliases with let/let!' unless respond_to?(:ruby_aliases)
    abort ':ruby_aliases must be an Array' unless ruby_aliases.is_a?(Array)
    with_mocked_rubies(fake_ruby, rubies_path, ruby_aliases, &example)
  end

  around(:each) do |example|
    nobundler!
    with_environment('BASHCOV_COMMAND_NAME' => example.full_description, &example)
  end

  before(:each) do
    allow(Gem).to receive(:user_home).and_return(Aruba.config.home_directory)
  end

  it 'can be run' do
    exec_rbexec('true', :shell => shell, :ruby => ruby)
    expect(last_command_started).to be_successfully_executed

    exec_rbexec('false', :shell => shell, :ruby => ruby)
    expect(last_command_started).not_to be_successfully_executed
  end

  it 'can be sourced' do
    run_rbexec_in_shell(:shell => shell)
    expect(last_command_started).to be_successfully_executed
  end

  context 'after the rbexec function runs' do
    let(:allowed) do
      %w[rbexec_shell rbexec_rubies rbexec_sourced rbexec_auto_add_rubies].map(&:upcase)
    end

    let!(:stdout) do
      run_rbexec_in_shell('true', 'set', :ruby => ruby, :shell => shell)
      stop_all_commands
      last_command_started.stdout
    end

    let(:set_vars) do
      stdout.each_line.select { |l| l =~ /^\w+=/ }.map { |l| l.split('=', 2).first }
    end

    let(:set_functions) do
      stdout.each_line.select { |l| l =~ /^\w+\s+\(\)$/ }.map { |l| l.split(/\s+/).first }
    end

    it 'does not pollute the environment with variables' do
      expect(stdout).not_to be_empty
      rbexec_vars = set_vars.grep(/\A_*rbexec/i)
      expect(rbexec_vars - allowed).to be_empty
    end

    it 'does not pollute the environment with functions' do
      unless %w[bash zsh].include? shell.first
        skip "#{shell.shelljoin} does not display functions in `set` output"
      end

      rbexec_functions = set_functions.grep(/rbexec/)
      expect(rbexec_functions - ['rbexec']).to be_empty
    end
  end

  it 'sets up the environment' do
    [:rbexec_environment, :rbexec_shell_environment].each do |env_method|
      send(env_method, :shell => shell, :ruby => ruby).tap do |re|
        [
          ['RUBY_ENGINE', 'RUBY_ENGINE', rbexec.ruby_engine],
          ['RUBY_VERSION', 'RbConfig::CONFIG["ruby_version"] or RUBY_VERSION', rbexec.ruby_version],
          ['GEM_ROOT', 'Gem.default_dir', rbexec.gem_root],
          ['GEM_HOME', 'Gem.user_dir', rbexec.gem_home],
          ['GEM_PATH', 'GEM_PATH', rbexec.gem_path],
        ].each do |k, n, e|
          expect(re).to include(k), "environment contains #{k}"
          expect(re[k]).to eq(e), "#{k} (#{re[k]}) is #{n} (#{e})"
        end

        expect(re).to include('PATH'), 'environment contains PATH'
        path = re['PATH'].split(':')
        expect(path[0]).to eq(File.join(re['GEM_HOME'], 'bin')), 'First $PATH entry is $GEM_HOME/bin'
        expect(path[1]).to eq(File.join(re['GEM_ROOT'], 'bin')), 'Second $PATH entry is $GEM_ROOT/bin'
        expect(path[2]).to eq(File.dirname(ruby)), "Third element in $PATH is Ruby's bindir"
      end
    end
  end

  context 'when no command is given' do
    let(:rbexec_rubies) { %w[winken blinken nod] }

    it 'prints the list of rubies in $RBEXEC_RUBIES' do
      env = { 'RBEXEC_RUBIES' => rbexec_rubies.join(':'), 'RBEXEC_AUTO_ADD_RUBIES' => '0' }
      with_environment env do
        exec_rbexec(:shell => shell)
        # ignore bashcov/simplecov coverage generation message by only grabbing
        # the first several lines, which should represent the contents of
        # $RBEXEC_RUBIES
        rbexec_rubies_output = last_command_started.stdout.each_line.take(rbexec_rubies.count).map(&:strip)
        expect(rbexec_rubies_output).to eq(rbexec_rubies)
      end
    end

    context 'with a Ruby activated' do
      let(:rbexec_rubies) { %w[winken blinken nod] << ruby }

      it 'prints an asterisk before the activated ruby' do
        with_environment 'RBEXEC_RUBIES' => rbexec_rubies.join(':') do
          activated_ruby = rbexec_activated_ruby(:shell => shell, :ruby => ruby)
          expect(activated_ruby).to eq ruby
        end
      end
    end
  end

  context 'given the path to a directory' do
    context 'in which the child path bin/ruby' do
      context 'exists' do
        it 'selects that Ruby' do
          exec_rbexec('date', :shell => shell, :ruby => File.expand_path('../..', ruby))
          expect(last_command_started).to be_successfully_executed
        end
      end

      context 'does not exist' do
        it 'complains and exits' do
          Tempfile.open('rbexec') do |f|
            bindir = File.expand_path('../bin', f.path)
            FileUtils.mkdir_p bindir
            exec_rbexec(:shell => shell, :ruby => bindir)
            expect(last_command_started).not_to be_successfully_executed
            expect(last_command_started.stderr).to include('does not exist')
          end
        end
      end
    end
  end

  context 'given a string', :mock_rubies => true do
    let!(:ruby_aliases) do
      %w[
        1.9.3
        2.1.0
        2.1.8
        2.2.7
        2.3.5
        2.4.1
        2.4.2
        2.5.0
      ]
    end

    context 'not matching an entry in RBEXEC_RUBIES' do
      it 'issues an error' do
        bad_ruby = SecureRandom.uuid
        exec_rbexec(:shell => shell, :ruby => bad_ruby)
        expect(last_command_started).not_to be_successfully_executed
        expect(last_command_started.stderr).to include("#{bad_ruby} does not exist!")
      end
    end

    context 'matching a single entry in RBEXEC_RUBIES' do
      it 'activates that Ruby' do
        activated_ruby = rbexec_activated_ruby(:shell => shell, :ruby => '2.2.7')
        expect(activated_ruby).not_to be(nil), 'No Ruby is activated'
        expect(activated_ruby).to include('2.2.7'), 'A Ruby other than 2.2.7 is activated'
      end
    end

    context 'matching more than one entry in RBEXEC_RUBIES' do
      it 'activates the last-matching Ruby' do
        activated_ruby = rbexec_activated_ruby(:shell => shell, :ruby => '2')
        expect(activated_ruby).not_to be(nil), 'No Ruby is activated'
        expect(activated_ruby).to include('2.5.0'), 'A Ruby other than 2.5.0 is activated'
      end
    end

    context 'given a path with redundant path separators and dots' do
      let(:rbexec_rubies) { %w[too///many//.////.//slashes//.//bin/ruby] }

      it 'removes all but one' do
        with_environment('RBEXEC_RUBIES' => rbexec_rubies.join(':')) do
          exec_rbexec(:shell => shell)
        end

        printed_rubies = last_command_started.stdout.each_line.to_a
        expect(printed_rubies).not_to be_empty
        expect(printed_rubies.first.strip).to eq 'too/many/slashes/bin/ruby'
      end
    end
  end

  context 'given the path to a file' do
    context 'that does not exist' do
      it 'complains and exits' do
        exec_rbexec(:shell => shell, :ruby => expand_path("probably/not/here/#{SecureRandom.uuid}"))
        expect(last_command_started).not_to be_successfully_executed
        expect(last_command_started.stderr).to include('does not exist')
      end
    end

    context 'that is not executable' do
      it 'complains and exits' do
        require 'tempfile'
        Tempfile.open('rbexec') do |f|
          exec_rbexec(:shell => shell, :ruby => f.path)
          expect(last_command_started).not_to be_successfully_executed
          expect(last_command_started.stderr).to include('is not executable')
        end
      end
    end

    context 'that is not a Ruby interpreter' do
      context 'but kind of looks like one' do
        it 'times out, then exits' do
          with_environment 'RBEXEC_TIMEOUT' => '1' do
            exec_rbexec(:shell => shell, :ruby => which('grep'))
            expect(last_command_started).not_to be_successfully_executed
            expect(last_command_started.stderr).to include('does not appear to be a Ruby executable')
          end
        end
      end

      context 'otherwise' do
        it 'complains and exits' do
          exec_rbexec(:shell => shell, :ruby => '/usr/bin/env')
          expect(last_command_started).not_to be_successfully_executed
          expect(last_command_started.stderr).to include('does not appear to be a Ruby executable')
        end
      end
    end
  end

  describe 'RBEXEC_RUBIES' do
    around(:each) do |example|
      with_environment('RBEXEC_AUTO_ADD_RUBIES' => '0', 'RBEXEC_RUBIES' => rbexec_rubies.join(':'), &example)
    end

    context 'given a directory', :mock_rubies => true do
      context 'that exists' do
        context 'and contains no Rubies' do
          let(:ruby_aliases) { %w[ruby-here] }

          it 'omits it from the list of Rubies' do
            empty_ruby_bin = rubies_path.join('ruby-empty/bin')
            empty_ruby_bin.mkpath

            with_environment('RBEXEC_RUBIES' => (rbexec_rubies + [empty_ruby_bin.parent]).join(':')) do
              printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

              expect(printed_rubies).not_to be_empty
              expect(printed_rubies).not_to include(/\A#{Regexp.escape(empty_ruby_bin.to_s)}/)
            end
          end
        end

        context 'and contains some Rubies' do
          let(:ruby_aliases) { %w[foo bar baz quux] }

          it 'adds them to the list of Rubies' do
            printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

            expect(printed_rubies).not_to be_empty

            printed_rubies.take(rbexec_rubies.count).each do |printed_ruby|
              expect(printed_ruby).to satisfy('match exactly one entry in $RBEXEC_RUBIES') do |v|
                rbexec_rubies.one? { |rbexec_ruby| v.start_with? rbexec_ruby }
              end
            end
          end
        end
      end

      context 'that does not exist' do
        let(:ruby_aliases) { %w[ruby-here] }

        it 'omits it from the list of Rubies' do
          noent_ruby = rubies_path.join(SecureRandom.uuid)

          with_environment('RBEXEC_RUBIES' => (rbexec_rubies + [noent_ruby.parent]).join(':')) do
            printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

            expect(printed_rubies).not_to be_empty
            expect(printed_rubies).not_to include(/\A#{Regexp.escape(noent_ruby.to_s)}/)
          end
        end
      end
    end
  end

  describe 'RBEXEC_AUTO_ADD_RUBIES' do
    let(:rbexec_auto_add_ruby_dirs) do
      %w[
        ~/.rubies ~/.rvm/rubies ~/.rbenv/versions ~/.rbfu/rubies /opt/rubies
      ].map { |d| Pathname.new(d).expand_path }
    end

    let(:rbexec_auto_add_ruby_dirs_noent) { rbexec_auto_add_ruby_dirs.reject(&:exist?) }

    context 'when set to "1"', :mock_rubies => true do
      around(:each) do |example|
        with_environment('RBEXEC_AUTO_ADD_RUBIES' => '1', &example)
      end

      let!(:ruby_aliases) do
        %w[
          1.8.7
          1.9.3
          2.1.8
          2.2.5
          2.3.1
          2.4.2
          2.5.0
        ]
      end

      it 'automatically appends various Rubies to RBEXEC_RUBIES' do
        printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

        printed_rubies.take(rbexec_rubies.count).each do |printed_ruby|
          expect(printed_ruby).to satisfy('match exactly one entry in $RBEXEC_RUBIES') do |v|
            rbexec_rubies.one? { |rbexec_ruby| v.start_with? rbexec_ruby }
          end
        end
      end

      context 'when RBEXEC_RUBIES already contains Rubies that would be auto-added' do
        let(:rbexec_rubies) { [rubies_path.join('2.3.1')] }

        it 'does not re-add them' do
          with_environment 'RBEXEC_RUBIES' => rbexec_rubies.join(':') do
            printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

            expect(printed_rubies.first).to start_with rbexec_rubies.first.to_s
            expect(rbexec_rubies.first.to_s).to satisfy("appear once in the listed Rubies (#{printed_rubies})") do |v|
              printed_rubies.one? { |printed_ruby| printed_ruby.start_with? v }
            end
          end
        end
      end

      context 'when an auto-added directory does not exist' do
        it 'displays no Rubies under those directories' do
          skip 'All auto-added Ruby directories are present on your system' if rbexec_auto_add_ruby_dirs_noent.empty?

          printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

          rbexec_auto_add_ruby_dirs_noent.each do |dir|
            expect(printed_rubies).not_to include(start_with(dir.to_s))
          end
        end
      end

      context 'when an auto-added directory is empty' do
        around(:each) do |example|
          parent_noent = []

          rbexec_auto_add_ruby_dirs_noent.each do |dir|
            find_first_missing_parent_path(dir).tap do |parent|
              parent_noent << parent unless parent.nil?
            end

            dir.mkpath
          end

          example.run

          parent_noent.each(&:rmtree)
        end

        let(:rbexec_auto_add_ruby_dirs_empty) { rbexec_auto_add_ruby_dirs.select { |dir| dir.children.empty? } }

        it 'displays no Rubies under those directories' do
          skip 'No empty auto-added Ruby directories are present on your system' if rbexec_auto_add_ruby_dirs_empty.empty?

          printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)

          rbexec_auto_add_ruby_dirs_empty.each do |dir|
            expect(printed_rubies).not_to include(start_with(dir.to_s))
          end
        end
      end

      context 'when an auto-added child directory contains no Rubies' do
        it 'does not append any Rubies under that directory' do
          empty_ruby_bin = rubies_path.join('ruby-empty/bin')
          empty_ruby_bin.mkpath
          printed_rubies = rbexec_available_rubies(:shell => shell, :ruby => ruby)
          expect(printed_rubies).not_to include(/\A#{Regexp.escape(empty_ruby_bin.to_s)}/)
        end
      end
    end

    context 'when not set to "1"' do
      it 'does not automatically append Rubies to RBEXEC_RUBIES' do
        # Bashcov writes a single-line diagnostic message upon exit
        expected_line_count = File.basename(Array(shell).first) == 'bashcov' ? 1 : 0

        with_environment 'RBEXEC_AUTO_ADD_RUBIES' => '0' do
          exec_rbexec(:shell => shell)
          expect(last_command_started.stdout.lines.count).to eq expected_line_count
        end
      end
    end
  end
end
