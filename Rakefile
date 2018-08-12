# frozen_string_literal: true

require 'pathname'

lib = Pathname.new('../lib').expand_path(__FILE__).to_s
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'rbexec/rake_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  %w[rubocop rubocop:auto_correct].each { |name| task(name) }
end

begin
  require 'kramdown/man/task'
  Kramdown::Man::Task.new
rescue LoadError
  task(:man)
end

RbExec::RakeTask.new.tap do |tasklib|
  manpath_for = ->(mp) do
    mp = Pathname.new(mp)
    tasklib.install_path_for('share', 'man', "man#{mp.extname[-1]}", mp.basename.sub_ext(''))
  end

  man_pages = []
  Rake::Task[:man].prerequisites.each do |src|
    man_pages << (dest = manpath_for.call(src)).to_s
    file dest.to_s => src.to_s do |t|
      mkdir_p File.dirname(t.name)
      install src.to_s, t.name
    end
  end

  tasklib.install_task.enhance(man_pages)
end

[:rubocop, :spec, :man].tap do |default_tasks|
  default_tasks.each do |task_name|
    Rake::Task[task_name].enhance ['rbexec:generate']
  end

  task :default => default_tasks
end
