# frozen_string_literal: true

require 'down'
require 'spec_helper'

describe RakeDependencies::Tasks::Download do
  include_context 'rake'

  # rubocop:disable Metrics/MethodLength
  def define_task(opts = {}, &block)
    namespace :dependency do
      opts = { dependency: 'super-cool-tool' }.merge(opts)
      described_class.define(opts) do |t|
        t.path = 'vendor/dependency'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template =
          'https://example.com/<%= @version %>/super-cool-tool-' \
          '<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template =
          'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
        block&.call(t)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # TODO: Check that it throws if required parameters are not supplied

  it 'adds a download task in the namespace in which it is created' do
    define_task

    expect(Rake.application)
      .to(have_task_defined('dependency:download'))
  end

  it 'gives the download task a description' do
    define_task(dependency: 'the-thing')

    expect(Rake::Task['dependency:download'].full_comment)
      .to(eq('Download the-thing distribution'))
  end

  it 'allows the task name to be overridden' do
    define_task(name: :fetch)

    expect(Rake.application)
      .to(have_task_defined('dependency:fetch'))
  end

  it 'allows multiple download tasks to be declared' do
    namespace :dependency1 do
      described_class.define(dependency: 'super-cool-tool1') do |t|
        t.path = 'vendor/dependency1'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template =
          'https://example.com/<%= @version %>/super-cool-tool-' \
          '<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template =
          'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
      end
    end

    namespace :dependency2 do
      described_class.define(dependency: 'super-cool-tool2') do |t|
        t.path = 'vendor/dependency2'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template =
          'https://example.com/<%= @version %>/super-cool-tool-' \
          '<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template =
          'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
      end
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[dependency1:download
               dependency2:download]
          ))
  end

  it 'recursively makes the download path' do
    define_task
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(task.creator)
      .to(have_received(:mkdir_p)
            .with('vendor/dependency/dist'))
  end

  it 'constructs a URI from the provided template, version, and type and ' \
     'downloads that URI' do
    define_task
    use_platform('arm64-darwin-21')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('https://example.com/1.2.3/super-cool-tool-darwin-arm64' \
                  '.tar.gz'))
  end

  it 'copies the downloaded file to the download path using the download ' \
     'file name template' do
    define_task
    use_platform('arm64-darwin-21')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    File.write('/download_file', 'download_content')
    allow(Down)
      .to(receive(:download)
            .and_return(File.new('/download_file')))
    allow(task.creator).to(receive(:cp))

    task.invoke

    expect(task.creator)
      .to(have_received(:cp)
            .with('/download_file',
                  'vendor/dependency/dist/super-cool-tool-darwin.tar.gz'))
  end

  it 'passes a platform CPU name of "amd64" for x86_64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    use_platform('x86_64-darwin')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('amd64'))
  end

  it 'passes a platform CPU name of "amd64" for x64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    use_platform('x64-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('amd64'))
  end

  it 'passes a platform CPU name of "386" for x86 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    use_platform('x86-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('386'))
  end

  it 'passes a platform CPU name of "arm" for arm by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    use_platform('arm-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('arm'))
  end

  it 'passes a platform CPU name of "arm64" for arm64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    use_platform('arm64-darwin-21')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('arm64'))
  end

  it 'passes the provided platform CPU name for x86_64 when present' do
    define_task do |t|
      t.platform_cpu_names = { x86_64: 'x86_64' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('x86_64-darwin')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('x86_64'))
  end

  it 'passes the provided platform CPU name for x64 when present' do
    define_task do |t|
      t.platform_cpu_names = { x64: 'x86_64' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('x64-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('x86_64'))
  end

  it 'passes the provided platform CPU name for x86 when present' do
    define_task do |t|
      t.platform_cpu_names = { x86: 'x86' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('x86-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('x86'))
  end

  it 'passes the provided platform CPU name for arm when present' do
    define_task do |t|
      t.platform_cpu_names = { arm: 'armv4' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('arm-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('armv4'))
  end

  it 'passes the provided platform CPU name for arm64 when present' do
    define_task do |t|
      t.platform_cpu_names = { arm64: 'armv9' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('arm64-darwin-21')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('armv9'))
  end

  it 'passes the provided platform CPU name for another arch when present' do
    define_task do |t|
      t.platform_cpu_names = { powerpc: 'powerpc' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    use_platform('powerpc-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('powerpc'))
  end

  it 'passes a platform OS name of "darwin" on darwin by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    use_platform('arm64-darwin-21')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('darwin'))
  end

  it 'passes a platform OS name of "linux" on linux by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    use_platform('x86_64-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('linux'))
  end

  it 'passes a platform OS name of "windows" on mswin32 by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    use_platform('x86-mswin32')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('windows'))
  end

  it 'passes a platform OS name of "windows" on mswin64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    use_platform('x86_64-mswin64')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('windows'))
  end

  it 'passes the provided platform OS name for darwin when present' do
    define_task do |t|
      t.platform_os_names = { darwin: 'mac', linux: 'linux64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    use_platform('x86_64-darwin')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('mac'))
  end

  it 'passes the provided platform OS name for linux when present' do
    define_task do |t|
      t.platform_os_names = { darwin: 'mac', linux: 'linux64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    use_platform('x86_64-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('linux64'))
  end

  it 'passes the provided platform OS name for mswin32 when present' do
    define_task do |t|
      t.platform_os_names = { mswin32: 'mswin32' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    use_platform('i686-mswin32')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('mswin32'))
  end

  it 'passes the provided platform OS name for mswin64 when present' do
    define_task do |t|
      t.platform_os_names = { mswin64: 'mswin64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    use_platform('x64-mswin64')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('mswin64'))
  end

  it 'passes the provided platform OS name for another OS when present' do
    define_task do |t|
      t.platform_os_names = { aix: 'aix' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    use_platform('x86-aix')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('aix'))
  end

  it 'uses an extension of .zip when type is zip' do
    define_task do |t|
      t.type = :zip
      t.uri_template = '<%= @ext %>'
    end
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('.zip'))
  end

  it 'uses an extension of .tgz when type is tgz' do
    define_task do |t|
      t.type = :tgz
      t.uri_template = '<%= @ext %>'
    end
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('.tgz'))
  end

  it 'uses no extension when type is uncompressed' do
    define_task do |t|
      t.type = :uncompressed
      t.uri_template = '<%= @ext %>'
    end
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with(''))
  end

  it 'uses the provided platform specific extension when a map is passed as ' \
     'the type' do
    define_task do |t|
      t.type = { darwin: :zip, linux: :tar_gz }
      t.uri_template = '<%= @ext %>'
    end
    use_platform('x86_64-linux')

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(Down)
      .to(have_received(:download)
            .with('.tar.gz'))
  end

  it 'raises an error when an unknown type is supplied' do
    define_task do |t|
      t.type = :wat
      t.uri_template = '<%= @ext %>'
    end
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    expect do
      task.invoke
    end.to raise_error(RuntimeError, 'Unknown type: wat')
  end

  it 'allows the distribution directory to be overridden' do
    define_task { |t| t.distribution_directory = 'spinach' }
    use_default_platform

    task = Rake::Task['dependency:download']

    stub_external_calls(task)

    task.invoke

    expect(task.creator)
      .to(have_received(:mkdir_p)
            .with('vendor/dependency/spinach'))
  end

  def use_platform(string)
    allow(Gem::Platform)
      .to(receive(:local)
            .and_return(Gem::Platform.new(string)))
  end

  def use_default_platform
    use_platform('arm64-darwin-21')
  end

  def stub_external_calls(task)
    stub_download
    stub_make_directory(task)
    stub_copy(task)
  end

  def stub_download
    File.write('/tmp_file', 'content')
    allow(Down)
      .to(receive(:download)
            .and_return(File.new('/tmp_file')))
  end

  def stub_make_directory(task)
    allow(task.creator).to(receive(:mkdir_p))
  end

  def stub_copy(task)
    allow(task.creator).to(receive(:cp))
  end
end
