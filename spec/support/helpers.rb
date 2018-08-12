# frozen_string_literal: true

require 'aruba/api'
require 'rbconfig'
require 'rubygems'

# :nocov:
begin
  require 'rbexec'
rescue LoadError
  abort 'Unable to load RbExec; have you run `rake rbexec:generate`?'
end
# :nocov:

module Helpers
  include Aruba::Api

module_function

  def rbexec_bin_path
    RbExec.bin_path
  end

  def exec_command(*ary)
    ary, opts = extract_opts(*ary)
    run_command_and_stop(ary.map(&:to_s).shelljoin, opts)
  end

  def exec_rbexec(*ary)
    shell, ruby, cmd, opts = preprocess_cmd(*ary)
    exec_command(*shell, rbexec_bin_path, *ruby, *cmd, opts)
  end

  def run_in_shell_with_rbexec_sourced(*ary)
    # NOTE - when run via shells other than bash and zsh, rbexec is limited to
    # a weak heuristic (checking that the value of $0 matches sh, dash, etc.)
    # for determining whether it has been sourced or executed as a script.
    # Using File.basename(shell.first) as the first parameter to the inline
    # command ensures that this check will succeed.
    shell, _, cmd, opts = preprocess_cmd(*ary)
    cmd.unshift '. "$1"'
    exec_command(*shell, '-c', cmd.join(";"), File.basename(shell.first), rbexec_bin_path, opts)
  end

  def run_rbexec_in_shell(*ary)
    _, ruby, cmd, opts = preprocess_cmd(*ary)
    cmd[0] = "rbexec #{ruby.shelljoin} #{cmd[0]}" unless cmd.empty?
    run_in_shell_with_rbexec_sourced(*cmd, opts)
  end

  def rbexec_environment(*ary)
    run_printenv { exec_rbexec('printenv', *ary) }
  end

  def rbexec_shell_environment(*ary)
    run_printenv do
      _, _, cmd, opts = preprocess_cmd(*ary)
      run_rbexec_in_shell(*cmd, 'printenv', opts)
    end
  end

  def run_rbexec_with_rbexec(opts = {})
    exec_rbexec(rbexec_bin_path, opts)
  end

  def rbexec_available_rubies_with_activation_status(opts = {})
    map_activated = ->(l) do
      l.strip!

      if l.start_with? '* '
        [l[2..-1], true]
      else
        [l, false]
      end
    end

    run_rbexec_with_rbexec(opts)
    Hash[last_command_started.stdout.each_line.map(&map_activated)]
  end

  def rbexec_available_rubies(opts = {})
    rbexec_available_rubies_with_activation_status(opts).keys
  end

  def rbexec_activated_ruby(opts = {})
    return unless (found = rbexec_available_rubies_with_activation_status(opts).find { |_, v| v })
    found.first
  end

  def nobundler!
    bundler_keys = ENV.keys.select { |k| k.start_with? 'BUNDLER' } + %w[RUBYLIB RUBYOPT]
    bundler_keys.each { |k| delete_environment_variable(k) }
  end

  def mock_rubies(ruby, dir, aliases = [])
    return if aliases.empty?

    Pathname.new(dir).tap do |base|
      base.mkpath
      aliases.uniq.each do |as|
        ruby_dest = base.join(as, 'bin', 'ruby')
        ruby_dest.parent.mkpath
        FileUtils.copy(ruby, ruby_dest)
        ruby_dest.chmod(0o755)
      end
    end
  end

  def with_mocked_rubies(ruby, dir, aliases = [])
    return if aliases.empty? || !block_given?
    path = mock_rubies(ruby, dir, aliases)
    yield path
  ensure
    unless path.nil?
      if path.root?
        # :nocov:
        warn "Refusing to recursively remove /"
        # :nocov:
      else
        path.rmtree
      end
    end
  end

  def printenv_kv_to_h(lines)
    Hash[lines.map { |l| l.strip.split('=', 2) }]
  end

  def run_printenv
    yield
    stop_all_commands
    printenv_kv_to_h(last_command_started.stdout.each_line)
  end

  def extract_opts(*ary)
    ary.pop if opts = Hash.try_convert(ary.last)
    [ary, opts || {}]
  end

  def preprocess_cmd(*ary)
    ary, opts = extract_opts(*ary)

    ruby = opts.key?(:ruby) ? Array(opts[:ruby]) : []
    shell = Array(opts.fetch(:shell, 'sh'))

    [shell, ruby, ary, opts]
  end

  def find_first_missing_parent_path(path)
    Pathname.new(path).ascend do |p|
      return p if p.parent.exist?
    end
  end
end
