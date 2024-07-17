# frozen_string_literal: true

require 'rake_dependencies/null_logger'
require 'rake_dependencies/tasks'
require 'rake_dependencies/task_sets'
require 'rake_dependencies/extractors'
require 'rake_dependencies/template'
require 'rake_dependencies/version'

module RakeDependencies
  class << self
    def define_tasks(&)
      TaskSets::All.define(&)
    end
  end
end
