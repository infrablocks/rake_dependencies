require 'spec_helper'
require 'fileutils'

describe RakeDependencies::TaskSets::All do
  include_context :rake

  def define_tasks(opts = {}, &block)
    subject.define({
        namespace: :some_namespace,
        dependency: 'super-cool-tool',
        version: '1.2.3',
        path: 'vendor/dependency',
        uri_template:
            'https://example.com/<%= @version %>/' +
                'super-cool-tool-<%= @os_id %>' +
                '-x86_64<%= @ext %>',
        file_name_template: 'super-cool-tool-<%= @os_id %><%= @ext %>',
        needs_fetch: lambda { |_| true }
    }.merge(opts), &block)
  end

  def double_allowing(*messages)
    instance = double
    messages.each do |message|
      allow(instance).to(receive(message))
    end
    instance
  end

  it 'adds tasks in the provided namespace when supplied' do
    define_tasks(namespace: :important_dependency)

    expect(Rake::Task['important_dependency:clean']).not_to be_nil
    expect(Rake::Task['important_dependency:download']).not_to be_nil
    expect(Rake::Task['important_dependency:extract']).not_to be_nil
    expect(Rake::Task['important_dependency:fetch']).not_to be_nil
    expect(Rake::Task['important_dependency:ensure']).not_to be_nil

    expect { Rake::Task['important_dependency:install'] }
        .to raise_error(RuntimeError)
  end

  it 'includes an install task in the provided namespace when installation ' +
      'directory and namespace supplied' do
    define_tasks(
        namespace: :important_dependency,
        installation_directory: 'some/important/directory'
    )

    expect(Rake::Task['important_dependency:clean']).not_to be_nil
    expect(Rake::Task['important_dependency:download']).not_to be_nil
    expect(Rake::Task['important_dependency:extract']).not_to be_nil
    expect(Rake::Task['important_dependency:install']).not_to be_nil
    expect(Rake::Task['important_dependency:fetch']).not_to be_nil
    expect(Rake::Task['important_dependency:ensure']).not_to be_nil
  end

  it 'adds tasks in the root namespace when none supplied' do
    define_tasks(namespace: nil)

    expect(Rake::Task['clean']).not_to be_nil
    expect(Rake::Task['download']).not_to be_nil
    expect(Rake::Task['extract']).not_to be_nil
    expect(Rake::Task['fetch']).not_to be_nil
    expect(Rake::Task['ensure']).not_to be_nil

    expect { Rake::Task['install'] }.to raise_error(RuntimeError)
  end

  it 'includes an install task in the root namespace when installation ' +
      'directory supplied and namespace not supplied' do
    define_tasks(
        namespace: nil,
        installation_directory: 'some/important/directory')

    expect(Rake::Task['clean']).not_to be_nil
    expect(Rake::Task['download']).not_to be_nil
    expect(Rake::Task['extract']).not_to be_nil
    expect(Rake::Task['install']).not_to be_nil
    expect(Rake::Task['fetch']).not_to be_nil
    expect(Rake::Task['ensure']).not_to be_nil
  end

  context 'clean task' do
    it 'uses a name of clean by default' do
      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:clean"))
          .to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(clean_task_name: :clean_it_up)

      expect(Rake::Task.task_defined?("some_namespace:clean_it_up"))
          .to(be(true))
    end

    it 'configures with the provided dependency and path' do
      dependency = 'some-dependency'
      path = 'in/this/path'

      define_tasks(
          dependency: dependency,
          path: path)

      clean_task = Rake::Task["some_namespace:clean"]

      expect(clean_task.creator.dependency).to(eq(dependency))
      expect(clean_task.creator.path).to(eq(path))
    end
  end

  context 'download task' do
    it 'uses a name of download by default' do
      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:download"))
          .to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(download_task_name: :download_it)

      expect(Rake::Task.task_defined?("some_namespace:download_it"))
          .to(be(true))
    end

    it 'configures with the provided dependency, path, type, version and ' +
        'templates' do
      dependency = 'some-dependency'
      path = 'in/this/path'
      version = '1.2.3'
      uri_template = 'https://example.com/<%= @version %>'
      file_name_template = '<%= @version %>'

      define_tasks(
          dependency: dependency,
          version: version,
          path: path,
          uri_template: uri_template,
          file_name_template: file_name_template)

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.dependency).to(eq(dependency))
      expect(download_task.creator.version).to(eq(version))
      expect(download_task.creator.path).to(eq(path))
      expect(download_task.creator.uri_template)
          .to(eq(uri_template))
      expect(download_task.creator.file_name_template)
          .to(eq(file_name_template))
    end

    it 'passes the default os_ids when none supplied' do
      define_tasks

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.os_ids)
          .to(eq({mac: 'mac', linux: 'linux'}))
    end

    it 'passes the provided os_ids when supplied' do
      define_tasks(os_ids: {mac: 'darwin', linux: 'linux64'})

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.os_ids)
          .to(eq({mac: 'darwin', linux: 'linux64'}))
    end

    it 'passes the default distribution_directory when none supplied' do
      define_tasks

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.distribution_directory)
          .to(eq('dist'))
    end

    it 'passes the provided distribution_directory when supplied' do
      define_tasks(distribution_directory: 'distributions')

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.distribution_directory)
          .to(eq('distributions'))
    end

    it 'uses a type of zip by default' do
      define_tasks

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.type)
          .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(type: :tar_gz)

      download_task = Rake::Task["some_namespace:download"]

      expect(download_task.creator.type)
          .to(eq(:tar_gz))
    end
  end

  context 'extract task' do
    it 'uses a name of download by default' do
      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:extract"))
          .to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      expect(Rake::Task.task_defined?("some_namespace:unarchive"))
          .to(be(true))
    end

    it 'configures with the provided dependency, path, type, version and ' +
        'template' do
      dependency = 'some-dependency'
      path = 'in/this/path'
      version = '1.2.3'
      file_name_template = '<%= @version %>'

      define_tasks(
          dependency: dependency,
          version: version,
          path: path,
          file_name_template: file_name_template)

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.dependency).to(eq(dependency))
      expect(extract_task.creator.version).to(eq(version))
      expect(extract_task.creator.path).to(eq(path))
      expect(extract_task.creator.file_name_template)
          .to(eq(file_name_template))
    end

    it 'passes the default os_ids when none supplied' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.os_ids).to(eq({mac: 'mac', linux: 'linux'}))
    end

    it 'passes the provided os_ids when supplied' do
      define_tasks(os_ids: {mac: 'darwin', linux: 'linux64'})

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.os_ids)
          .to(eq({mac: 'darwin', linux: 'linux64'}))
    end

    it 'passes the default distribution_directory when none supplied' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.distribution_directory)
          .to(eq('dist'))
    end

    it 'passes the provided distribution_directory when supplied' do
      define_tasks(distribution_directory: 'distributions')

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.distribution_directory)
          .to(eq('distributions'))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.binary_directory)
          .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(binary_directory: 'exe')

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.binary_directory)
          .to(eq('exe'))
    end

    it 'passes a nil strip path template when none supplied' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.strip_path_template)
          .to(be_nil)
    end

    it 'passes the provided strip path template when supplied' do
      define_tasks(strip_path_template: '<%= @version %>')

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.strip_path_template)
          .to(eq('<%= @version %>'))
    end

    it 'passes a nil target binary name template when none supplied' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.target_binary_name_template)
          .to(be_nil)
    end

    it 'passes the provided target binary name template when supplied' do
      define_tasks(target_binary_name_template: 'binary-<%= @version %>')

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.target_binary_name_template)
          .to(eq('binary-<%= @version %>'))
    end

    it 'uses a type of zip by default' do
      define_tasks

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.type)
          .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(type: :tar_gz)

      extract_task = Rake::Task["some_namespace:extract"]

      expect(extract_task.creator.type)
          .to(eq(:tar_gz))
    end
  end

  context 'install task' do
    it 'uses a name of install by default' do
      define_tasks(installation_directory: 'some/important/directory')

      expect(Rake::Task.task_defined?("some_namespace:install"))
    end

    it 'uses the provided name when supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          install_task_name: :copy)

      expect(Rake::Task.task_defined?("some_namespace:copy"))
    end

    it 'configures with the provided dependency, path, version and template' do
      dependency = 'some-dependency'
      path = 'in/this/path'
      version = '1.2.3'
      target_binary_name_template = 'some-binary'

      define_tasks(dependency: dependency,
          version: version,
          path: path,
          installation_directory: 'some/important/directory',
          target_binary_name_template: target_binary_name_template)

      install_task = Rake::Task["some_namespace:install"]

      stub_mkdir_p
      stub_cp

      install_task.invoke

      expect(install_task.creator.dependency).to(eq(dependency))
      expect(install_task.creator.version).to(eq(version))
      expect(install_task.creator.path).to(eq(path))
      expect(install_task.creator.binary_name_template)
          .to(eq(target_binary_name_template))
    end

    it 'passes the default os_ids when none supplied' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.os_ids)
          .to(eq({mac: 'mac', linux: 'linux'}))
    end

    it 'passes the provided os_ids when supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          os_ids: {mac: 'darwin', linux: 'linux64'})

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.os_ids)
          .to(eq({mac: 'darwin', linux: 'linux64'}))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.binary_directory)
          .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          binary_directory: 'exe')

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.binary_directory)
          .to(eq('exe'))
    end

    it 'passes the dependency name as binary name template when no target ' +
        'name template supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          dependency: 'some-dependency')

      install_task = Rake::Task["some_namespace:install"]

      stub_mkdir_p
      stub_cp

      install_task.invoke

      expect(install_task.creator.binary_name_template)
          .to(eq('some-dependency'))
    end

    it 'passes the target binary name template as binary name template when ' +
        'supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          target_binary_name_template: 'binary-<%= @version %>')

      install_task = Rake::Task["some_namespace:install"]

      stub_mkdir_p
      stub_cp

      install_task.invoke

      expect(install_task.creator.binary_name_template)
          .to(eq('binary-<%= @version %>'))
    end

    it 'uses a type of zip by default' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.type)
          .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(
          installation_directory: 'some/important/directory',
          type: :tar_gz)

      install_task = Rake::Task["some_namespace:install"]

      expect(install_task.creator.type)
          .to(eq(:tar_gz))
    end
  end

  context 'fetch task' do
    it 'uses a name of fetch by default' do
      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:fetch"))
          .to(eq(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(fetch_task_name: :get_it)

      expect(Rake::Task.task_defined?("some_namespace:get_it"))
          .to(eq(true))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(dependency: dependency)

      fetch_task = Rake::Task["some_namespace:fetch"]

      expect(fetch_task.creator.dependency).to(eq(dependency))
    end

    it 'uses a download task name of download by default' do
      define_tasks

      fetch_task = Rake::Task["some_namespace:fetch"]

      expect(fetch_task.creator.download_task_name)
          .to(eq(:download))
    end

    it 'uses the provided download task name when supplied' do
      define_tasks(download_task_name: :download_it)

      fetch_task = Rake::Task["some_namespace:fetch"]

      expect(fetch_task.creator.download_task_name)
          .to(eq(:download_it))
    end

    it 'uses an extract task name of extract by default' do
      define_tasks

      fetch_task = Rake::Task["some_namespace:fetch"]

      expect(fetch_task.creator.extract_task_name)
          .to(eq(:extract))
    end

    it 'uses the provided extract task name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      fetch_task = Rake::Task["some_namespace:fetch"]

      expect(fetch_task.creator.extract_task_name)
          .to(eq(:unarchive))
    end
  end

  context 'ensure task' do
    it 'uses a name of ensure by default' do
      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:ensure"))
    end

    it 'uses the provided name when supplied' do
      define_tasks(ensure_task_name: :ensure_it)

      define_tasks

      expect(Rake::Task.task_defined?("some_namespace:ensure_it"))
    end

    it 'configures with the provided dependency, version, path and ' +
        'needs_fetch callback' do
      dependency = 'some-dependency'
      version = '1.2.3'
      path = 'in/this/path'
      needs_fetch = lambda { |_| true }

      define_tasks(
          dependency: dependency,
          version: version,
          path: path,
          needs_fetch: needs_fetch)

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.dependency).to(eq(dependency))
      expect(ensure_task.creator.version).to(eq(version))
      expect(ensure_task.creator.path).to(eq(path))
      expect(ensure_task.creator.needs_fetch).to(eq(needs_fetch))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.binary_directory)
          .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(binary_directory: 'exe')

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.binary_directory)
          .to(eq('exe'))
    end

    it 'uses a clean task name of clean by default' do
      define_tasks

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.clean_task_name)
          .to(eq(:clean))
    end

    it 'uses the provided clean task name when supplied' do
      define_tasks(clean_task_name: :clean_it)

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.clean_task_name)
          .to(eq(:clean_it))
    end

    it 'uses a download task name of download by default' do
      define_tasks

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.download_task_name)
          .to(eq(:download))
    end

    it 'uses the provided download task name when supplied' do
      define_tasks(download_task_name: :download_it)

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.download_task_name)
          .to(eq(:download_it))
    end

    it 'uses an extract task name of extract by default' do
      define_tasks

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.extract_task_name)
          .to(eq(:extract))
    end

    it 'uses the provided extract task name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.extract_task_name)
          .to(eq(:unarchive))
    end

    it 'uses an install task name of install by default' do
      define_tasks

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.install_task_name)
          .to(eq(:install))
    end

    it 'uses the provided install task name when supplied' do
      define_tasks(install_task_name: :copy)

      ensure_task = Rake::Task["some_namespace:ensure"]

      expect(ensure_task.creator.install_task_name)
          .to(eq(:copy))
    end
  end

  def stub_cp
    allow_any_instance_of(Rake::TaskLib).to(receive(:cp))
  end

  def stub_mkdir_p
    allow_any_instance_of(Rake::TaskLib).to(receive(:mkdir_p))
  end
end
