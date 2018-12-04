# frozen_string_literal: true

if RUBY_VERSION >= '2.0.0'
  ruby '>= 1.9.3'
else
  ruby '1.9.3'
end

source 'https://rubygems.org' do
  group :test do
    gem 'aruba', '>= 1.0.0a', '< 1.1.0'
    # gem 'mutant-rspec', '~> 0.8'
    gem 'rake', '~> 10.0'
    gem 'rspec', '~> 3.0'
    gem 'simplecov'
    gem 'simplecov-console'

    if RUBY_VERSION >= '2.2.0'
      gem 'rubocop', '~> 0.50'
    end

    if RUBY_VERSION >= '2.4.0'
      gem 'bashcov', github: 'infertux/bashcov', branch: 'master'
      gem 'coveralls'
    end
  end

  group :development do
    if RUBY_VERSION >= '2.1.0'
      gem 'kramdown-man'
    end

    gem 'pry'
  end
end
