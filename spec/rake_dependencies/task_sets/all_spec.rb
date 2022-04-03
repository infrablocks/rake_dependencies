# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeDependencies::TaskSets::All do
  include_context 'rake'

  # rubocop:disable Metrics/MethodLength
  def define_tasks(opts = {}, &block)
    needs_fetch = ->(_) { true }
    default_opts = {
      namespace: :some_namespace,
      dependency: 'super-cool-tool',
      version: '1.2.3',
      path: 'vendor/dependency',
      uri_template:
        'https://example.com/<%= @version %>/' \
        'super-cool-tool-<%= @platform_os_name %>' \
        '-<%= @platform_cpu_name %><%= @ext %>',
      file_name_template:
        'super-cool-tool-<%= @platform_os_name %><%= @ext %>',
      needs_fetch: needs_fetch
    }
    resolved_opts = default_opts.merge(opts)

    RakeDependencies::TaskSets::All.define(resolved_opts, &block)
  end

  # rubocop:enable Metrics/MethodLength

  def double_allowing(*messages)
    instance = double
    messages.each do |message|
      allow(instance).to(receive(message))
    end
    instance
  end

  it 'adds tasks in the provided namespace when supplied' do
    define_tasks(namespace: :important_dependency)

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[important_dependency:clean
               important_dependency:download
               important_dependency:extract
               important_dependency:fetch
               important_dependency:ensure]
          ))
  end

  it 'does not add the install task by default when a namespace is provided' do
    define_tasks(namespace: :important_dependency)

    expect { Rake::Task['important_dependency:install'] }
      .to raise_error(RuntimeError)
  end

  it 'includes an install task in the provided namespace when installation ' \
     'directory and namespace supplied' do
    define_tasks(
      namespace: :important_dependency,
      installation_directory: 'some/important/directory'
    )

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[important_dependency:clean
               important_dependency:download
               important_dependency:extract
               important_dependency:install
               important_dependency:fetch
               important_dependency:ensure]
          ))
  end

  it 'adds tasks in the root namespace when none supplied' do
    define_tasks(namespace: nil)

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[clean
               download
               extract
               fetch
               ensure]
          ))
  end

  it 'does not add the install task by default when no namespace is provided' do
    define_tasks(namespace: nil)

    expect { Rake::Task['install'] }.to raise_error(RuntimeError)
  end

  it 'includes an install task in the root namespace when installation ' \
     'directory supplied and namespace not supplied' do
    define_tasks(
      namespace: nil,
      installation_directory: 'some/important/directory'
    )

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[clean
               download
               extract
               install
               fetch
               ensure]
          ))
  end

  describe 'clean task' do
    it 'uses a name of clean by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:clean'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(clean_task_name: :clean_it_up)

      expect(Rake.application)
        .to(have_task_defined('some_namespace:clean_it_up'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'
      path = 'in/this/path'

      define_tasks(
        dependency: dependency,
        path: path
      )

      clean_task = Rake::Task['some_namespace:clean']

      expect(clean_task.creator.dependency).to(eq(dependency))
    end

    it 'configures with the provided path' do
      dependency = 'some-dependency'
      path = 'in/this/path'

      define_tasks(
        dependency: dependency,
        path: path
      )

      clean_task = Rake::Task['some_namespace:clean']

      expect(clean_task.creator.path).to(eq(path))
    end
  end

  describe 'download task' do
    it 'uses a name of download by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:download'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(download_task_name: :download_it)

      expect(Rake.application)
        .to(have_task_defined('some_namespace:download_it'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(
        dependency: dependency
      )

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.dependency).to(eq(dependency))
    end

    it 'configures with the provided path' do
      path = 'in/this/path'

      define_tasks(
        path: path
      )

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.path).to(eq(path))
    end

    it 'configures with the provided version' do
      version = '1.2.3'

      define_tasks(
        version: version
      )

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.version).to(eq(version))
    end

    it 'configures with the provided uri template' do
      uri_template = 'https://example.com/<%= @version %>'

      define_tasks(
        uri_template: uri_template
      )

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.uri_template)
        .to(eq(uri_template))
    end

    it 'configures with the provided file name template' do
      file_name_template = '<%= @version %>'

      define_tasks(
        file_name_template: file_name_template
      )

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.file_name_template)
        .to(eq(file_name_template))
    end

    it 'passes the default platform OS names when none supplied' do
      define_tasks

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.platform_os_names)
        .to(eq(RakeDependencies::PlatformNames::OS))
    end

    it 'passes the provided platform OS names when supplied' do
      define_tasks(platform_os_names: { darwin: 'mac', linux: 'linux64' })

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.platform_os_names)
        .to(eq({ darwin: 'mac', linux: 'linux64' }))
    end

    it 'passes the default platform CPU names when none supplied' do
      define_tasks

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.platform_cpu_names)
        .to(eq(RakeDependencies::PlatformNames::CPU))
    end

    it 'passes the provided platform CPU names when supplied' do
      define_tasks(platform_cpu_names: { i686: 'x86', arm: 'armv4' })

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.platform_cpu_names)
        .to(eq({ i686: 'x86', arm: 'armv4' }))
    end

    it 'passes the default distribution_directory when none supplied' do
      define_tasks

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.distribution_directory)
        .to(eq('dist'))
    end

    it 'passes the provided distribution_directory when supplied' do
      define_tasks(distribution_directory: 'distributions')

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.distribution_directory)
        .to(eq('distributions'))
    end

    it 'uses a type of zip by default' do
      define_tasks

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.type)
        .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(type: :tar_gz)

      download_task = Rake::Task['some_namespace:download']

      expect(download_task.creator.type)
        .to(eq(:tar_gz))
    end
  end

  describe 'extract task' do
    it 'uses a name of download by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:extract'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      expect(Rake.application)
        .to(have_task_defined('some_namespace:unarchive'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(
        dependency: dependency
      )

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.dependency).to(eq(dependency))
    end

    it 'configures with the provided path' do
      path = 'in/this/path'

      define_tasks(
        path: path
      )

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.path).to(eq(path))
    end

    it 'configures with the provided version' do
      version = '1.2.3'

      define_tasks(
        version: version
      )

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.version).to(eq(version))
    end

    it 'configures with the provided file name template' do
      file_name_template = '<%= @version %>'

      define_tasks(
        file_name_template: file_name_template
      )

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.file_name_template)
        .to(eq(file_name_template))
    end

    it 'passes the default platform OS names when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.platform_os_names)
        .to(eq(RakeDependencies::PlatformNames::OS))
    end

    it 'passes the provided platform OS names when supplied' do
      define_tasks(platform_os_names: { darwin: 'mac', linux: 'linux64' })

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.platform_os_names)
        .to(eq({ darwin: 'mac', linux: 'linux64' }))
    end

    it 'passes the default platform CPU names when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.platform_cpu_names)
        .to(eq(RakeDependencies::PlatformNames::CPU))
    end

    it 'passes the provided platform CPU names when supplied' do
      define_tasks(platform_cpu_names: { i686: 'x86', arm: 'armv4' })

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.platform_cpu_names)
        .to(eq({ i686: 'x86', arm: 'armv4' }))
    end

    it 'passes the default distribution_directory when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.distribution_directory)
        .to(eq('dist'))
    end

    it 'passes the provided distribution_directory when supplied' do
      define_tasks(distribution_directory: 'distributions')

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.distribution_directory)
        .to(eq('distributions'))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.binary_directory)
        .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(binary_directory: 'exe')

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.binary_directory)
        .to(eq('exe'))
    end

    it 'passes a nil strip path template when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.strip_path_template)
        .to(be_nil)
    end

    it 'passes the provided strip path template when supplied' do
      define_tasks(strip_path_template: '<%= @version %>')

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.strip_path_template)
        .to(eq('<%= @version %>'))
    end

    it 'passes a nil target binary name template when none supplied' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.target_binary_name_template)
        .to(be_nil)
    end

    it 'passes the provided target binary name template when supplied' do
      define_tasks(target_binary_name_template: 'binary-<%= @version %>')

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.target_binary_name_template)
        .to(eq('binary-<%= @version %>'))
    end

    it 'uses a type of zip by default' do
      define_tasks

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.type)
        .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(type: :tar_gz)

      extract_task = Rake::Task['some_namespace:extract']

      expect(extract_task.creator.type)
        .to(eq(:tar_gz))
    end
  end

  describe 'install task' do
    it 'uses a name of install by default' do
      define_tasks(installation_directory: 'some/important/directory')

      expect(Rake.application)
        .to(have_task_defined('some_namespace:install'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        install_task_name: :copy
      )

      expect(Rake.application)
        .to(have_task_defined('some_namespace:copy'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(
        installation_directory: 'some/important/directory',
        dependency: dependency
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.dependency).to(eq(dependency))
    end

    it 'configures with the provided path' do
      path = 'in/this/path'

      define_tasks(
        installation_directory: 'some/important/directory',
        path: path
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.path).to(eq(path))
    end

    it 'configures with the provided version' do
      version = '1.2.3'

      define_tasks(
        installation_directory: 'some/important/directory',
        version: version
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.version).to(eq(version))
    end

    it 'configures with the provided installation directory' do
      installation_directory = 'some/important/directory'

      define_tasks(
        installation_directory: installation_directory
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.installation_directory)
        .to(eq(installation_directory))
    end

    it 'configures with the provided target binary name template' do
      target_binary_name_template = 'some-binary'

      define_tasks(
        installation_directory: 'some/important/directory',
        target_binary_name_template: target_binary_name_template
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.binary_name_template)
        .to(eq(target_binary_name_template))
    end

    it 'passes the default platform OS names when none supplied' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.platform_os_names)
        .to(eq(RakeDependencies::PlatformNames::OS))
    end

    it 'passes the provided platform OS names when supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        platform_os_names: { darwin: 'mac', linux: 'linux64' }
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.platform_os_names)
        .to(eq({ darwin: 'mac', linux: 'linux64' }))
    end

    it 'passes the default platform CPU names when none supplied' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.platform_cpu_names)
        .to(eq(RakeDependencies::PlatformNames::CPU))
    end

    it 'passes the provided platform CPU names when supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        platform_cpu_names: { i686: 'x86', arm: 'armv4' }
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.platform_cpu_names)
        .to(eq({ i686: 'x86', arm: 'armv4' }))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.binary_directory)
        .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        binary_directory: 'exe'
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.binary_directory)
        .to(eq('exe'))
    end

    it 'passes the dependency name as binary name template when no target ' \
       'name template supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        dependency: 'some-dependency'
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.binary_name_template)
        .to(eq('some-dependency'))
    end

    it 'passes the target binary name template as binary name template when ' \
       'supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        target_binary_name_template: 'binary-<%= @version %>'
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.binary_name_template)
        .to(eq('binary-<%= @version %>'))
    end

    it 'uses a type of zip by default' do
      define_tasks(installation_directory: 'some/important/directory')

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.type)
        .to(eq(:zip))
    end

    it 'uses the provided type when supplied' do
      define_tasks(
        installation_directory: 'some/important/directory',
        type: :tar_gz
      )

      install_task = Rake::Task['some_namespace:install']

      expect(install_task.creator.type)
        .to(eq(:tar_gz))
    end
  end

  describe 'fetch task' do
    it 'uses a name of fetch by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:fetch'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(fetch_task_name: :get_it)

      expect(Rake.application)
        .to(have_task_defined('some_namespace:get_it'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(dependency: dependency)

      fetch_task = Rake::Task['some_namespace:fetch']

      expect(fetch_task.creator.dependency).to(eq(dependency))
    end

    it 'uses a download task name of download by default' do
      define_tasks

      fetch_task = Rake::Task['some_namespace:fetch']

      expect(fetch_task.creator.download_task_name)
        .to(eq(:download))
    end

    it 'uses the provided download task name when supplied' do
      define_tasks(download_task_name: :download_it)

      fetch_task = Rake::Task['some_namespace:fetch']

      expect(fetch_task.creator.download_task_name)
        .to(eq(:download_it))
    end

    it 'uses an extract task name of extract by default' do
      define_tasks

      fetch_task = Rake::Task['some_namespace:fetch']

      expect(fetch_task.creator.extract_task_name)
        .to(eq(:extract))
    end

    it 'uses the provided extract task name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      fetch_task = Rake::Task['some_namespace:fetch']

      expect(fetch_task.creator.extract_task_name)
        .to(eq(:unarchive))
    end
  end

  describe 'ensure task' do
    it 'uses a name of ensure by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:ensure'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(ensure_task_name: :ensure_it)

      define_tasks

      expect(Rake.application)
        .to(have_task_defined('some_namespace:ensure_it'))
    end

    it 'configures with the provided dependency' do
      dependency = 'some-dependency'

      define_tasks(
        dependency: dependency
      )

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.dependency).to(eq(dependency))
    end

    it 'configures with the provided version' do
      version = '1.2.3'

      define_tasks(
        version: version
      )

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.version).to(eq(version))
    end

    it 'configures with the provided path' do
      path = 'in/this/path'

      define_tasks(
        path: path
      )

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.path).to(eq(path))
    end

    it 'configures with the provided needs_fetch callback' do
      needs_fetch = ->(_) { true }

      define_tasks(
        needs_fetch: needs_fetch
      )

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.needs_fetch).to(eq(needs_fetch))
    end

    it 'passes the default binary_directory when none supplied' do
      define_tasks

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.binary_directory)
        .to(eq('bin'))
    end

    it 'passes the provided binary_directory when supplied' do
      define_tasks(binary_directory: 'exe')

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.binary_directory)
        .to(eq('exe'))
    end

    it 'uses a clean task name of clean by default' do
      define_tasks

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.clean_task_name)
        .to(eq(:clean))
    end

    it 'uses the provided clean task name when supplied' do
      define_tasks(clean_task_name: :clean_it)

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.clean_task_name)
        .to(eq(:clean_it))
    end

    it 'uses a download task name of download by default' do
      define_tasks

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.download_task_name)
        .to(eq(:download))
    end

    it 'uses the provided download task name when supplied' do
      define_tasks(download_task_name: :download_it)

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.download_task_name)
        .to(eq(:download_it))
    end

    it 'uses an extract task name of extract by default' do
      define_tasks

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.extract_task_name)
        .to(eq(:extract))
    end

    it 'uses the provided extract task name when supplied' do
      define_tasks(extract_task_name: :unarchive)

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.extract_task_name)
        .to(eq(:unarchive))
    end

    it 'uses an install task name of install by default' do
      define_tasks

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.install_task_name)
        .to(eq(:install))
    end

    it 'uses the provided install task name when supplied' do
      define_tasks(install_task_name: :copy)

      ensure_task = Rake::Task['some_namespace:ensure']

      expect(ensure_task.creator.install_task_name)
        .to(eq(:copy))
    end
  end
end
