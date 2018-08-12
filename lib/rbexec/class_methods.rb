# frozen_string_literal: true

require 'pathname'

# Helper methods for figuring out where stuff lives
class RbExec
  class << self
    def source_root
      @source_root ||= Pathname.new('../../..').expand_path(__FILE__)
    end

    def bin_path
      @bin_path ||= source_root + 'bin/rbexec'
    end
  end
end
