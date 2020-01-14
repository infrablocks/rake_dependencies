require 'rake_dependencies/tasks'
require 'rake_dependencies/task_sets'
require 'rake_dependencies/extractors'
require 'rake_dependencies/template'
require 'rake_dependencies/version'

module RakeDependencies
  class << self
    def define_tasks(&block)
      TaskSets::All.define(&block)
    end
  end
end
