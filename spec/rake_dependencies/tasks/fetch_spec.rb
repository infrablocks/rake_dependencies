# frozen_string_literal: true

require 'spec_helper'

describe RakeDependencies::Tasks::Fetch do
  include_context 'rake'

  def define_task(opts = {}, &block)
    ns = opts[:namespace] || :dependency
    additional_tasks = opts[:additional_tasks] || %i[download extract]

    namespace ns do
      additional_tasks.each do |t|
        task t
      end

      subject.define({ dependency: 'some-dep' }.merge(opts)) do |t|
        block&.call(t)
      end
    end
  end

  describe 'task definition' do
    it 'adds a fetch task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:fetch']).not_to be_nil
    end

    it 'gives the fetch task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:fetch'].full_comment)
        .to(eq('Fetch the-thing'))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'downloads and extracts on invocation' do
      define_task

      task = Rake::Task['dependency:fetch']

      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))

      task.invoke

      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'allows multiple fetch tasks to be declared' do
      define_task(namespace: :dependency1)
      define_task(namespace: :dependency2)

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[dependency1:fetch
                 dependency2:fetch]
            ))
    end
  end

  describe 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :get)

      expect(Rake.application)
        .to(have_task_defined('dependency:get'))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the download task to be overridden' do
      define_task(additional_tasks: %i[dl extract]) do |t|
        t.download_task_name = :dl
      end

      task = Rake::Task['dependency:fetch']

      allow(Rake::Task['dependency:dl']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))

      task.invoke

      expect(Rake::Task['dependency:dl'])
        .to(have_received(:invoke)
              .ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke)
              .ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the extract task to be overridden' do
      define_task(additional_tasks: %i[download ex]) do |t|
        t.extract_task_name = :ex
      end

      task = Rake::Task['dependency:fetch']

      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:ex']).to(receive(:invoke))

      task.invoke

      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke)
              .ordered)
      expect(Rake::Task['dependency:ex'])
        .to(have_received(:invoke)
              .ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses the correct namespace for prerequisites when multiple fetch ' \
       'tasks are declared' do
      define_task(namespace: :dependency1)
      define_task(namespace: :dependency2)

      dependency1_task = Rake::Task['dependency1:fetch']
      dependency2_task = Rake::Task['dependency2:fetch']

      allow(Rake::Task['dependency1:download']).to(receive(:invoke))
      allow(Rake::Task['dependency1:extract']).to(receive(:invoke))
      allow(Rake::Task['dependency2:download']).to(receive(:invoke))
      allow(Rake::Task['dependency2:extract']).to(receive(:invoke))

      dependency1_task.invoke

      expect(Rake::Task['dependency1:download'])
        .to(have_received(:invoke)
              .ordered)
      expect(Rake::Task['dependency1:extract'])
        .to(have_received(:invoke)
              .ordered)

      dependency2_task.invoke

      expect(Rake::Task['dependency2:download'])
        .to(have_received(:invoke)
              .ordered)
      expect(Rake::Task['dependency2:extract'])
        .to(have_received(:invoke)
              .ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
