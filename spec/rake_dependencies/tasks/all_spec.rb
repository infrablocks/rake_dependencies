require 'spec_helper'
require 'fileutils'

describe RakeDependencies::Tasks::All do
  include_context :rake

  def define_tasks(&block)
    subject.new do |t|
      t.namespace = :some_namespace
      t.dependency = 'super-cool-tool'
      t.version = '1.2.3'
      t.path = 'vendor/dependency'

      t.uri_template = 'https://example.com/<%= @version %>/super-cool-tool-<%= @os_id %>-x86_64<%= @ext %>'
      t.file_name_template = 'super-cool-tool-<%= @os_id %><%= @ext %>'

      t.needs_fetch = lambda do |_|
        true
      end

      block.call(t) if block
    end
  end

  def double_allowing(*messages)
    instance = double
    messages.each do |message|
      allow(instance).to(receive(message))
    end
    instance
  end

  it 'adds all tasks in the provided namespace when supplied' do
    define_tasks do |t|
      t.namespace = :important_dependency
    end

    expect(Rake::Task['important_dependency:clean']).not_to be_nil
    expect(Rake::Task['important_dependency:download']).not_to be_nil
    expect(Rake::Task['important_dependency:extract']).not_to be_nil
    expect(Rake::Task['important_dependency:fetch']).not_to be_nil
    expect(Rake::Task['important_dependency:ensure']).not_to be_nil
  end

  context 'clean task' do
    it 'configures with the provided dependency and path' do
      dependency = 'some-dependency'
      path = 'in/this/path'

      clean_configurer = double_allowing(:dependency=, :path=, :name=)

      namespace :some_namespace do
        task :clean
      end

      expect(RakeDependencies::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:dependency=).with(dependency))
      expect(clean_configurer).to(receive(:path=).with(path))

      define_tasks do |t|
        t.dependency = dependency
        t.path = path
      end
    end

    it 'uses a name of clean by default' do
      clean_configurer = double_allowing(:dependency=, :path=, :name=)

      namespace :some_namespace do
        task :clean
      end

      expect(RakeDependencies::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:name=).with(:clean))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      clean_configurer = double_allowing(:dependency=, :path=, :name=)

      namespace :some_namespace do
        task :clean_it_up
      end

      expect(RakeDependencies::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:name=).with(:clean_it_up))

      define_tasks do |t|
        t.clean_task_name = :clean_it_up
      end
    end
  end

  context 'download task' do
    it 'configures with the provided dependency, path, type, version and templates' do
      dependency = 'some-dependency'
      path = 'in/this/path'
      version = '1.2.3'
      uri_template = 'https://example.com/<%= @version %>'
      file_name_template = '<%= @version %>'

      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer).to(receive(:dependency=).with(dependency))
      expect(download_configurer).to(receive(:version=).with(version))
      expect(download_configurer).to(receive(:path=).with(path))
      expect(download_configurer).to(receive(:uri_template=).with(uri_template))
      expect(download_configurer).to(receive(:file_name_template=).with(file_name_template))

      define_tasks do |t|
        t.dependency = dependency
        t.version = version
        t.path = path

        t.uri_template = uri_template
        t.file_name_template = file_name_template
      end
    end

    it 'passes the default os_ids when none supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer)
          .to(receive(:os_ids=).with({mac: 'mac', linux: 'linux'}))

      define_tasks
    end

    it 'passes the provided os_ids when supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer)
          .to(receive(:os_ids=).with({mac: 'darwin', linux: 'linux64'}))

      define_tasks do |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
      end
    end

    it 'passes the default distribution_directory when none supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer)
          .to(receive(:distribution_directory=).with('dist'))

      define_tasks
    end

    it 'passes the provided distribution_directory when supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer)
          .to(receive(:distribution_directory=).with('distributions'))

      define_tasks do |t|
        t.distribution_directory = 'distributions'
      end
    end

    it 'uses a type of zip by default' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer).to(receive(:type=).with(:zip))

      define_tasks
    end

    it 'uses the provided type when supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer).to(receive(:type=).with(:tar_gz))

      define_tasks do |t|
        t.type = :tar_gz
      end
    end

    it 'uses a name of download by default' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer).to(receive(:name=).with(:download))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      download_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :uri_template=, :file_name_template=,
          :os_ids=, :distribution_directory=)

      namespace :some_namespace do
        task :download_it
      end

      expect(RakeDependencies::Tasks::Download)
          .to(receive(:new).and_yield(download_configurer))
      expect(download_configurer).to(receive(:name=).with(:download_it))

      define_tasks do |t|
        t.download_task_name = :download_it
      end
    end
  end

  context 'extract task' do
    it 'configures with the provided dependency, path, type, version and template' do
      dependency = 'some-dependency'
      path = 'in/this/path'
      version = '1.2.3'
      file_name_template = '<%= @version %>'

      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer).to(receive(:dependency=).with(dependency))
      expect(extract_configurer).to(receive(:version=).with(version))
      expect(extract_configurer).to(receive(:path=).with(path))
      expect(extract_configurer).to(receive(:file_name_template=).with(file_name_template))

      define_tasks do |t|
        t.dependency = dependency
        t.version = version
        t.path = path

        t.file_name_template = file_name_template
      end
    end

    it 'passes the default os_ids when none supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:os_ids=).with({mac: 'mac', linux: 'linux'}))

      define_tasks
    end

    it 'passes the provided os_ids when supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:os_ids=).with({mac: 'darwin', linux: 'linux64'}))

      define_tasks do |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
      end
    end

    it 'passes the default distribution_directory when none supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:distribution_directory=).with('dist'))

      define_tasks
    end

    it 'passes the provided distribution_directory when supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:distribution_directory=).with('distributions'))

      define_tasks do |t|
        t.distribution_directory = 'distributions'
      end
    end

    it 'passes the default binary_directory when none supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:binary_directory=).with('bin'))

      define_tasks
    end

    it 'passes the provided binary_directory when supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer)
          .to(receive(:binary_directory=).with('exe'))

      define_tasks do |t|
        t.binary_directory = 'exe'
      end
    end

    it 'uses a type of zip by default' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer).to(receive(:type=).with(:zip))

      define_tasks
    end

    it 'uses the provided type when supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer).to(receive(:type=).with(:tar_gz))

      define_tasks do |t|
        t.type = :tar_gz
      end
    end

    it 'uses a name of download by default' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :extract
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer).to(receive(:name=).with(:extract))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      extract_configurer = double_allowing(
          :dependency=, :version=, :path=, :type=, :name=,
          :file_name_template=, :os_ids=,
          :distribution_directory=, :binary_directory=)

      namespace :some_namespace do
        task :unarchive
      end

      expect(RakeDependencies::Tasks::Extract)
          .to(receive(:new).and_yield(extract_configurer))
      expect(extract_configurer).to(receive(:name=).with(:unarchive))

      define_tasks do |t|
        t.extract_task_name = :unarchive
      end
    end
  end

  context 'fetch task' do
    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:dependency=).with(dependency))

      define_tasks do |t|
        t.dependency = dependency
      end
    end

    it 'uses a name of fetch by default' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:name=).with(:fetch))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :get_it
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:name=).with(:get_it))

      define_tasks do |t|
        t.fetch_task_name = :get_it
      end
    end

    it 'uses a download task name of download by default' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:download_task=).with(:download))

      define_tasks
    end

    it 'uses the provided download task name when supplied' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:download_task=).with(:download_it))

      define_tasks do |t|
        t.download_task_name = :download_it
      end
    end

    it 'uses an extract task name of extract by default' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:extract_task=).with(:extract))

      define_tasks
    end

    it 'uses the provided extract task name when supplied' do
      fetch_configurer = double_allowing(
          :dependency=, :name=, :download_task=, :extract_task=)

      namespace :some_namespace do
        task :fetch
      end

      expect(RakeDependencies::Tasks::Fetch)
          .to(receive(:new).and_yield(fetch_configurer))
      expect(fetch_configurer).to(receive(:extract_task=).with(:unarchive))

      define_tasks do |t|
        t.extract_task_name = :unarchive
      end
    end
  end

  context 'ensure task' do
    it 'configures with the provided dependency, version, path and needs_fetch callback' do
      dependency = 'some-dependency'
      version = '1.2.3'
      path = 'in/this/path'
      needs_fetch = lambda { |_| true }

      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:dependency=).with(dependency))
      expect(ensure_configurer).to(receive(:version=).with(version))
      expect(ensure_configurer).to(receive(:path=).with(path))
      expect(ensure_configurer).to(receive(:needs_fetch=).with(needs_fetch))

      define_tasks do |t|
        t.dependency = dependency
        t.version = version
        t.path = path
        t.needs_fetch = needs_fetch
      end
    end

    it 'uses a name of ensure by default' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:name=).with(:ensure))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure_it
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:name=).with(:ensure_it))

      define_tasks do |t|
        t.ensure_task_name = :ensure_it
      end
    end

    it 'passes the default binary_directory when none supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer)
          .to(receive(:binary_directory=).with('bin'))

      define_tasks
    end

    it 'passes the provided binary_directory when supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer)
          .to(receive(:binary_directory=).with('exe'))

      define_tasks do |t|
        t.binary_directory = 'exe'
      end
    end

    it 'uses a clean task name of clean by default' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:clean_task=).with(:clean))

      define_tasks
    end

    it 'uses the provided clean task name when supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:clean_task=).with(:clean_it))

      define_tasks do |t|
        t.clean_task_name = :clean_it
      end
    end

    it 'uses a download task name of download by default' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:download_task=).with(:download))

      define_tasks
    end

    it 'uses the provided download task name when supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:download_task=).with(:download_it))

      define_tasks do |t|
        t.download_task_name = :download_it
      end
    end

    it 'uses an extract task name of extract by default' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:extract_task=).with(:extract))

      define_tasks
    end

    it 'uses the provided extract task name when supplied' do
      ensure_configurer = double_allowing(
          :dependency=, :path=, :version=, :needs_fetch=,
          :clean_task=, :download_task=, :extract_task=,
          :name=, :binary_directory=)

      namespace :some_namespace do
        task :ensure
      end

      expect(RakeDependencies::Tasks::Ensure)
          .to(receive(:new).and_yield(ensure_configurer))
      expect(ensure_configurer).to(receive(:extract_task=).with(:unarchive))

      define_tasks do |t|
        t.extract_task_name = :unarchive
      end
    end
  end
end
