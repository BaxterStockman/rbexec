require 'pathname'
require 'simplecov'
require 'simplecov-console'

module SilenceFormatting
  def silent
    return unless block_given?
    stdout, $stdout = $stdout, StringIO.new
    yield
  ensure
    $stdout = stdout
  end

  def format(result)
    silent { super }
  end
end

class SilentHTMLFormatter < SimpleCov::Formatter::HTMLFormatter
  include SilenceFormatting
end

class SilentConsoleFormatter < SimpleCov::Formatter::Console
  include SilenceFormatting
end

def formatters(silent = false)
  [].tap do |f|
    if silent
      f << SilentHTMLFormatter << SilentConsoleFormatter
    else
      f << SimpleCov::Formatter::HTMLFormatter << SimpleCov::Formatter::Console
    end

    if RUBY_VERSION >= '2.2.7'
      require 'coveralls'
      f << Coveralls::SimpleCov::Formatter
    end
  end
end

def multi_formatter(silent = false)
  SimpleCov::Formatter::MultiFormatter.new(formatters(silent))
end

SimpleCov.profiles.define 'rbexec_base' do
  load_profile  'bundler_filter'

  add_group     'Sources',  %w[bin lib]
  add_group     'Tests',    'spec'
  add_filter    'tmp*'
  add_filter    '/spec/fixtures/'

  Pathname.new(__FILE__).parent.tap do |r|
    add_filter do |src|
      Pathname.new(src.filename).relative_path_from(r).each_filename.any? { |e| e.start_with? '.' }
    end

    root          r
    coverage_dir  r + 'coverage'
  end
end

SimpleCov.profiles.define 'rbexec_rspec' do
  load_profile  'rbexec_base'
  formatter     multi_formatter
end

SimpleCov.profiles.define 'rbexec_bashcov' do
  load_profile  'rbexec_base'
  command_name  ENV.fetch('BASHCOV_COMMAND_NAME', $0)
  formatter     multi_formatter(true)

  Coveralls::Output.silent = true if defined? Coveralls::Output
end

SimpleCov.load_profile 'rbexec_bashcov' if ENV.key? 'BASHCOV_COMMAND_NAME'
