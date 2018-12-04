# frozen_string_literal: true

def try_define_tasks(lib_name, *task_names)
  yield if block_given?
rescue LoadError
  task_names.each do |task_name|
    task(task_name) do |t|
      warn "#{lib_name} is not available; unable to run task `#{t.name}'."
    end
  end
end

require 'pathname'

lib = Pathname.new('../lib').expand_path(__FILE__).to_s
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'rbexec/rake_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

try_define_tasks(*%w[rubocop rubocop rubocop:auto_correct]) do
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

try_define_tasks(*%w[kramdown-man man]) do
  require 'kramdown/man/task'
  Kramdown::Man::Task.new
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
