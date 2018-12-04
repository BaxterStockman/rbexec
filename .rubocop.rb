# frozen_string_literal: true

# :(
# ...but it's easier than fixing RuboCop to respect the
# AllCops/TargetRubyVersion in the "top" config when constructing
# subordinate/"inherit_from" configs
module RuboCop
  class Config
    def target_ruby_version
      @target_ruby_version ||= KNOWN_RUBIES.select { |kr| kr.to_s <= RUBY_VERSION }.max
    end
  end
end
