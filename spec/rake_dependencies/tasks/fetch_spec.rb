require 'spec_helper'

describe RakeDependencies::Tasks::Fetch do
  include_context :rake

  def define_task(name = nil, options = {}, &block)
    ns = options[:namespace] || :dependency
    additional_tasks = options[:additional_tasks] || [:download, :extract]

    namespace ns do
      additional_tasks.each do |t|
        task t
      end

      subject.new(*(name ? [name] : [])) do |t|
        t.dependency = 'some-dep'
        block.call(t) if block
      end
    end
  end

  context 'task definition' do
    it 'adds a fetch task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:fetch']).not_to be_nil
    end

    it 'gives the fetch task a description' do
      define_task { |t| t.dependency = 'the-thing' }

      expect(rake.last_description).to(eq('Fetch the-thing'))
    end

    it 'configures the fetch task to depend on the download and extract tasks' do
      define_task

      task = Rake::Task['dependency:fetch']

      expect(task.prerequisite_tasks).to(eq([
          Rake::Task['dependency:download'],
          Rake::Task['dependency:extract']
      ]))
    end

    it 'allows multiple fetch tasks to be declared' do
      define_task(nil, namespace: :dependency1)
      define_task(nil, namespace: :dependency2)

      expect(Rake::Task['dependency1:fetch']).not_to be_nil
      expect(Rake::Task['dependency2:fetch']).not_to be_nil
    end
  end

  context 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(:get)

      expect(Rake::Task['dependency:get']).not_to be_nil
    end

    it 'allows the download task to be overridden' do
      define_task(nil, additional_tasks: [:dl, :extract]) do |t|
        t.download_task = :dl
      end

      task = Rake::Task['dependency:fetch']

      expect(task.prerequisite_tasks).to(include(Rake::Task['dependency:dl']))
    end

    it 'allows the extract task to be overridden' do
      define_task(nil, additional_tasks: [:download, :ex]) do |t|
        t.extract_task = :ex
      end

      task = Rake::Task['dependency:fetch']

      expect(task.prerequisite_tasks).to(include(Rake::Task['dependency:ex']))
    end

    it 'uses the correct namespace for prerequisites when multiple fetch tasks are declared' do
      define_task(nil, namespace: :dependency1)
      define_task(nil, namespace: :dependency2)

      dependency1_task = Rake::Task['dependency1:fetch']
      dependency2_task = Rake::Task['dependency2:fetch']

      expect(dependency1_task.prerequisite_tasks).to(eq([
          Rake::Task['dependency1:download'],
          Rake::Task['dependency1:extract']
      ]))
      expect(dependency2_task.prerequisite_tasks).to(eq([
          Rake::Task['dependency2:download'],
          Rake::Task['dependency2:extract']
      ]))
    end
  end
end
