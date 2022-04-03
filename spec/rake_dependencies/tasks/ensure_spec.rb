# frozen_string_literal: true

require 'spec_helper'

describe RakeDependencies::Tasks::Ensure do
  include_context 'rake'

  # rubocop:disable Metrics/MethodLength
  def define_task(opts = {}, &block)
    ns = opts[:namespace] || :dependency
    additional_tasks =
      opts[:additional_tasks] || %i[clean download extract install]

    namespace ns do
      additional_tasks.each do |t|
        task t
      end

      subject.define({ dependency: 'some-dep' }.merge(opts)) do |t|
        t.path = 'some/path'
        block&.call(t)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  describe 'task definition' do
    it 'adds an ensure task in the namespace in which it is created' do
      define_task

      expect(Rake.application)
        .to(have_task_defined('dependency:ensure'))
    end

    it 'gives the ensure task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:ensure'].full_comment)
        .to(eq('Ensure the-thing present'))
    end

    it 'allows multiple fetch tasks to be declared' do
      define_task(namespace: :dependency1)
      define_task(namespace: :dependency2)

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[dependency1:ensure
                 dependency2:ensure]
            ))
    end
  end

  describe 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :fetch_if_needed)

      expect(Rake.application)
        .to(have_task_defined('dependency:fetch_if_needed'))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the clean task to be overridden' do
      define_task(
        additional_tasks: %i[tidy download extract install]
      ) do |t|
        t.clean_task_name = :tidy
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:tidy']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))
      allow(Rake::Task['dependency:install']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:tidy'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:install'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the download task to be overridden' do
      define_task(additional_tasks: %i[clean dl extract install]) do |t|
        t.download_task_name = :dl
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:dl']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))
      allow(Rake::Task['dependency:install']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:dl'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:install'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the extract task to be overridden' do
      define_task(
        additional_tasks: %i[clean download unarchive install]
      ) do |t|
        t.extract_task_name = :unarchive
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:unarchive']).to(receive(:invoke))
      allow(Rake::Task['dependency:install']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:unarchive'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:install'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the install task to be overridden' do
      define_task(
        additional_tasks: %i[clean download extract copy]
      ) do |t|
        t.install_task_name = :copy
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))
      allow(Rake::Task['dependency:copy']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:copy'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'does not invoke the install task if it is not defined' do
      define_task(
        additional_tasks: %i[clean download extract]
      ) do |t|
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'when invoking the fetch required checker' do
    it 'passes an object with the path and default binary directory and ' \
       'version' do
      needs_fetch_checker = instance_double(Proc)
      define_task do |t|
        t.path = 'some/path'
        t.needs_fetch = needs_fetch_checker
      end

      allow(needs_fetch_checker).to(receive(:call).and_return(false))

      Rake::Task['dependency:ensure'].invoke

      expect(needs_fetch_checker)
        .to(have_received(:call)
              .at_least(:once)
              .with(satisfy do |t|
                t.version.nil? &&
                  t.path == 'some/path' &&
                  t.binary_directory == 'bin'
              end))
    end

    it 'passes the supplied version' do
      needs_fetch_checker = instance_double(Proc)
      define_task do |t|
        t.version = '0.1.0'
        t.path = 'some/path'
        t.needs_fetch = needs_fetch_checker
      end

      allow(needs_fetch_checker).to(receive(:call).and_return(false))

      Rake::Task['dependency:ensure'].invoke

      expect(needs_fetch_checker)
        .to(have_received(:call)
              .at_least(:once)
              .with(satisfy do |t|
                t.version == '0.1.0' &&
                  t.path == 'some/path' &&
                  t.binary_directory == 'bin'
              end))
    end

    it 'passes the supplied binary_directory' do
      needs_fetch_checker = instance_double(Proc)
      define_task do |t|
        t.path = 'some/path'
        t.binary_directory = 'exe'
        t.needs_fetch = needs_fetch_checker
      end

      allow(needs_fetch_checker).to(receive(:call).and_return(false))

      Rake::Task['dependency:ensure'].invoke

      expect(needs_fetch_checker)
        .to(have_received(:call)
              .at_least(:once)
              .with(satisfy do |t|
                t.version.nil? &&
                  t.path == 'some/path' &&
                  t.binary_directory == 'exe'
              end))
    end
  end

  context 'when the supplied fetch required checker returns true' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'invokes clean, download and extract tasks' do
      define_task do |t|
        t.needs_fetch = ->(_) { true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:download'])
        .to(have_received(:invoke).ordered)
      expect(Rake::Task['dependency:extract'])
        .to(have_received(:invoke).ordered)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'when the supplied fetch required checker returns false' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'does nothing' do
      define_task do |t|
        t.needs_fetch = ->(_) { false }
      end

      ensure_task = Rake::Task['dependency:ensure']

      allow(Rake::Task['dependency:clean']).to(receive(:invoke))
      allow(Rake::Task['dependency:download']).to(receive(:invoke))
      allow(Rake::Task['dependency:extract']).to(receive(:invoke))

      ensure_task.invoke

      expect(Rake::Task['dependency:clean'])
        .not_to(have_received(:invoke))
      expect(Rake::Task['dependency:download'])
        .not_to(have_received(:invoke))
      expect(Rake::Task['dependency:extract'])
        .not_to(have_received(:invoke))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
