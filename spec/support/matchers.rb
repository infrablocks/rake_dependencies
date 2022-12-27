# frozen_string_literal: true

RSpec::Matchers.define :have_task_defined do |expected|
  match do |actual|
    !actual.lookup(expected).nil?
  end
  failure_message do |_|
    "expected Rake to have the a #{expected} task defined but it didn't"
  end
end

RSpec::Matchers.define :have_tasks_defined do |expected|
  define_method :composite_matcher do
    expected.drop(1).inject(have_task_defined(expected.first)) do |m, task|
      m.and(have_task_defined(task))
    end
  end
  match do |actual|
    composite_matcher.matches?(actual)
  end
  failure_message do |actual|
    expected_task_set = Set.new(expected)
    actual_task_set = Set.new(actual.tasks.map(&:name))

    'expected Rake to have the following tasks defined: ' \
      "#{expected.pretty_inspect}but the following tasks were not defined: " \
      "#{(expected_task_set - actual_task_set).to_a.pretty_inspect}"
  end
  description do
    composite_matcher.description
  end
end
