require 'spec_helper'

describe RakeDependencies::Tasks::Ensure do
  include_context :rake

  def define_task(opts = {}, &block)
    ns = opts[:namespace] || :dependency
    additional_tasks = opts[:additional_tasks] ||
        [:clean, :download, :extract, :install]

    namespace ns do
      additional_tasks.each do |t|
        task t
      end

      subject.define({dependency: 'some-dep'}.merge(opts)) do |t|
        t.path = 'some/path'
        block.call(t) if block
      end
    end
  end

  context 'task definition' do
    it 'adds an ensure task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:ensure']).not_to be_nil
    end

    it 'gives the ensure task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:ensure'].full_comment)
          .to(eq('Ensure the-thing present'))
    end

    it 'allows multiple fetch tasks to be declared' do
      define_task(namespace: :dependency1)
      define_task(namespace: :dependency2)

      expect(Rake::Task['dependency1:ensure']).not_to be_nil
      expect(Rake::Task['dependency2:ensure']).not_to be_nil
    end
  end

  context 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :fetch_if_needed)

      expect(Rake::Task['dependency:fetch_if_needed']).not_to be_nil
    end

    it 'allows the clean task to be overridden' do
      define_task(
          additional_tasks: [:tidy, :download, :extract, :install]) do |t|
        t.clean_task_name = :tidy
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:tidy']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:download']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:extract']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:install']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end

    it 'allows the download task to be overridden' do
      define_task(additional_tasks: [:clean, :dl, :extract, :install]) do |t|
        t.download_task_name = :dl
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:dl']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:extract']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:install']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end

    it 'allows the extract task to be overridden' do
      define_task(
          additional_tasks: [:clean, :download, :unarchive, :install]) do |t|
        t.extract_task_name = :unarchive
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:download']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:unarchive']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:install']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end

    it 'allows the install task to be overridden' do
      define_task(
          additional_tasks: [:clean, :download, :extract, :copy]) do |t|
        t.install_task_name = :copy
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:download']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:extract']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:copy']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end

    it 'does not invoke the install task if it is not defined' do
      define_task(
          additional_tasks: [:clean, :download, :extract]) do |t|
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:download']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:extract']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end
  end

  context 'when invoking the fetch required checker' do
    it 'passes an object with the path and default binary directory and ' +
        'version' do
      needs_fetch_checker = double('checker')
      define_task do |t|
        t.path = 'some/path'
        t.needs_fetch = needs_fetch_checker
      end

      expect(needs_fetch_checker)
          .to(receive(:arity).at_least(:once).and_return(1))
      expect(needs_fetch_checker)
          .to(receive(:call)
              .at_least(:once)
              .with(satisfy { |t|
                t.version == nil &&
                    t.path == 'some/path' &&
                    t.binary_directory == 'bin'
              })
              .and_return(false))

      Rake::Task['dependency:ensure'].invoke
    end

    it 'passes the supplied version' do
      needs_fetch_checker = double('checker')
      define_task do |t|
        t.version = '0.1.0'
        t.path = 'some/path'
        t.needs_fetch = needs_fetch_checker
      end

      expect(needs_fetch_checker)
          .to(receive(:arity).at_least(:once).and_return(1))
      expect(needs_fetch_checker)
          .to(receive(:call)
              .at_least(:once)
              .with(satisfy { |t|
                t.version == '0.1.0' &&
                    t.path == 'some/path' &&
                    t.binary_directory == 'bin'
              })
              .and_return(false))

      Rake::Task['dependency:ensure'].invoke
    end

    it 'passes the supplied binary_directory' do
      needs_fetch_checker = double('checker')
      define_task do |t|
        t.path = 'some/path'
        t.binary_directory = 'exe'
        t.needs_fetch = needs_fetch_checker
      end

      expect(needs_fetch_checker)
          .to(receive(:arity).at_least(:once).and_return(1))
      expect(needs_fetch_checker)
          .to(receive(:call)
              .at_least(:once)
              .with(satisfy { |t|
                t.version == nil &&
                    t.path == 'some/path' &&
                    t.binary_directory == 'exe'
              })
              .and_return(false))

      Rake::Task['dependency:ensure'].invoke
    end
  end

  context 'when the supplied fetch required checker returns true' do
    it 'invokes clean, download and extract tasks' do
      define_task do |t|
        t.needs_fetch = lambda { |_| true }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:download']).to(receive(:invoke).ordered)
      expect(Rake::Task['dependency:extract']).to(receive(:invoke).ordered)

      ensure_task.invoke
    end
  end

  context 'when the supplied fetch required checker returns false' do
    it 'does nothing' do
      define_task do |t|
        t.needs_fetch = lambda { |_| false }
      end

      ensure_task = Rake::Task['dependency:ensure']

      expect(Rake::Task['dependency:clean']).not_to(receive(:invoke))
      expect(Rake::Task['dependency:download']).not_to(receive(:invoke))
      expect(Rake::Task['dependency:extract']).not_to(receive(:invoke))

      ensure_task.invoke
    end
  end
end
