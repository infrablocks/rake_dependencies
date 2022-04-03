# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeDependencies::Tasks::Clean do
  include_context 'rake'

  it 'adds a clean task in the namespace in which it is created' do
    namespace :dependency do
      described_class.define(dependency: 'something') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake.application)
      .to(have_task_defined('dependency:clean'))
  end

  it 'gives the clean task a description' do
    namespace :dependency do
      described_class.define(dependency: 'the-thing') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:clean'].full_comment)
      .to(eq('Clean vendored the-thing'))
  end

  it 'allows the task name to be overridden' do
    namespace :dependency do
      described_class.define(name: :remove, dependency: 'something') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake.application)
      .to(have_task_defined('dependency:remove'))
  end

  it 'allows multiple clean tasks to be declared' do
    namespace :dependency1 do
      described_class.define(dependency: 'something1') do |t|
        t.path = 'some/path/for/1'
      end
    end

    namespace :dependency2 do
      described_class.define(dependency: 'something2') do |t|
        t.path = 'some/path/for/2'
      end
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[dependency1:clean
               dependency2:clean]
          ))
  end

  it 'recursively removes the dependency download path' do
    path = 'vendor/dependency'

    described_class.define(dependency: 'something') do |t|
      t.path = path
    end

    task = Rake::Task['clean']

    allow(task.creator)
      .to(receive(:rm_rf))

    task.invoke

    expect(task.creator)
      .to(have_received(:rm_rf)
            .with(path))
  end

  it 'fails if no path is provided' do
    described_class.define(dependency: 'something')

    expect do
      Rake::Task['clean'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end
end
