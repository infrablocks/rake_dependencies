require 'spec_helper'

describe RakeDependencies::Tasks::Download do
  include_context :rake

  def define_task(opts = {}, &block)
    namespace :dependency do
      subject.define({ dependency: 'super-cool-tool' }.merge(opts)) do |t|
        t.path = 'vendor/dependency'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template = 'https://example.com/<%= @version %>/super-cool-tool-<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template = 'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
        block.call(t) if block
      end
    end
  end

  def set_platform_to(string)
    allow(Gem::Platform)
      .to(receive(:local)
            .and_return(Gem::Platform.new(string)))
  end

  def set_platform
    set_platform_to('arm64-darwin-21')
  end

  def stub_external_calls
    stub_open_uri
    stub_make_directory
    stub_copy
  end

  def stub_open_uri
    File.open('/tmp_file', 'w') { |f| f.write('content') }
    allow(URI).to(receive(:open).and_return(File.new('/tmp_file')))
  end

  def stub_make_directory
    allow_any_instance_of(subject).to(receive(:mkdir_p))
  end

  def stub_copy
    allow_any_instance_of(subject).to(receive(:cp))
  end

  # TODO: Check that it throws if required parameters are not supplied

  it 'adds a download task in the namespace in which it is created' do
    define_task

    expect(Rake::Task['dependency:download']).not_to be_nil
  end

  it 'gives the download task a description' do
    define_task(dependency: 'the-thing')

    expect(Rake::Task['dependency:download'].full_comment)
      .to(eq('Download the-thing distribution'))
  end

  it 'allows the task name to be overridden' do
    define_task(name: :fetch)

    expect(Rake::Task['dependency:fetch']).not_to be_nil
  end

  it 'allows multiple download tasks to be declared' do
    namespace :dependency1 do
      subject.define(dependency: 'super-cool-tool1') do |t|
        t.path = 'vendor/dependency1'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template = 'https://example.com/<%= @version %>/super-cool-tool-<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template = 'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
      end
    end

    namespace :dependency2 do
      subject.define(dependency: 'super-cool-tool2') do |t|
        t.path = 'vendor/dependency2'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template = 'https://example.com/<%= @version %>/super-cool-tool-<%= @platform_os_name %>-<%= @platform_cpu_name %><%= @ext %>'
        t.file_name_template = 'super-cool-tool-<%= @platform_os_name %><%= @ext %>'
      end
    end

    dependency1_download = Rake::Task['dependency1:download']
    dependency2_download = Rake::Task['dependency2:download']

    expect(dependency1_download).not_to be_nil
    expect(dependency2_download).not_to be_nil
  end

  it 'recursively makes the download path' do
    define_task
    set_platform
    stub_external_calls

    expect_any_instance_of(subject)
      .to(receive(:mkdir_p)
            .with('vendor/dependency/dist'))

    Rake::Task['dependency:download'].invoke
  end

  it 'constructs a URI from the provided template, version, and type and downloads that URI' do
    define_task
    set_platform_to('arm64-darwin-21')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('https://example.com/1.2.3/super-cool-tool-darwin-arm64.tar.gz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'copies the downloaded file to the download path using the download file name template' do
    define_task
    set_platform_to('arm64-darwin-21')
    stub_external_calls

    File.open('/download_file', 'w') { |f| f.write('download_content') }
    allow(URI)
      .to(receive(:open)
            .and_return(File.new('/download_file')))

    expect_any_instance_of(subject)
      .to(receive(:cp)
            .with('/download_file', 'vendor/dependency/dist/super-cool-tool-darwin.tar.gz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform CPU name of "amd64" for x86_64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    set_platform_to('x86_64-darwin')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('amd64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform CPU name of "amd64" for x64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    set_platform_to('x64-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('amd64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform CPU name of "386" for x86 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    set_platform_to('x86-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('386'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform CPU name of "arm" for arm by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    set_platform_to('arm-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('arm'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform CPU name of "arm64" for arm64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_cpu_name %>' }
    set_platform_to('arm64-darwin-21')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('arm64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for x86_64 when present' do
    define_task do |t|
      t.platform_cpu_names = { x86_64: 'x86_64' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('x86_64-darwin')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('x86_64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for x64 when present' do
    define_task do |t|
      t.platform_cpu_names = { x64: 'x86_64' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('x64-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('x86_64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for x86 when present' do
    define_task do |t|
      t.platform_cpu_names = { x86: 'x86' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('x86-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('x86'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for arm when present' do
    define_task do |t|
      t.platform_cpu_names = { arm: 'armv4' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('arm-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('armv4'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for arm64 when present' do
    define_task do |t|
      t.platform_cpu_names = { arm64: 'armv9' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('arm64-darwin-21')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('armv9'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform CPU name for another arch when present' do
    define_task do |t|
      t.platform_cpu_names = { powerpc: 'powerpc' }
      t.uri_template = '<%= @platform_cpu_name %>'
    end
    set_platform_to('powerpc-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('powerpc'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform OS name of "darwin" on darwin by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    set_platform_to('arm64-darwin-21')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('darwin'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform OS name of "linux" on linux by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    set_platform_to('x86_64-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('linux'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform OS name of "windows" on mswin32 by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    set_platform_to('x86-mswin32')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('windows'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes a platform OS name of "windows" on mswin64 by default' do
    define_task { |t| t.uri_template = '<%= @platform_os_name %>' }
    set_platform_to('x86_64-mswin64')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('windows'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform OS name for darwin when present' do
    define_task do |t|
      t.platform_os_names = { darwin: 'mac', linux: 'linux64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    set_platform_to('x86_64-darwin')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('mac'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform OS name for linux when present' do
    define_task do |t|
      t.platform_os_names = { darwin: 'mac', linux: 'linux64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    set_platform_to('x86_64-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('linux64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform OS name for mswin32 when present' do
    define_task do |t|
      t.platform_os_names = { mswin32: 'mswin32' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    set_platform_to('i686-mswin32')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('mswin32'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform OS name for mswin64 when present' do
    define_task do |t|
      t.platform_os_names = { mswin64: 'mswin64' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    set_platform_to('x64-mswin64')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('mswin64'))

    Rake::Task['dependency:download'].invoke
  end

  it 'passes the provided platform OS name for another OS when present' do
    define_task do |t|
      t.platform_os_names = { aix: 'aix' }
      t.uri_template = '<%= @platform_os_name %>'
    end
    set_platform_to('x86-aix')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('aix'))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses an extension of .zip when type is zip' do
    define_task do |t|
      t.type = :zip
      t.uri_template = '<%= @ext %>'
    end
    set_platform
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('.zip'))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses an extension of .tgz when type is tgz' do
    define_task do |t|
      t.type = :tgz
      t.uri_template = '<%= @ext %>'
    end
    set_platform
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('.tgz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses no extension when type is uncompressed' do
    define_task do |t|
      t.type = :uncompressed
      t.uri_template = '<%= @ext %>'
    end
    set_platform
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with(''))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses the provided platform specific extension when a map is passed as the type' do
    define_task do |t|
      t.type = { darwin: :zip, linux: :tar_gz }
      t.uri_template = '<%= @ext %>'
    end
    set_platform_to('x86_64-linux')
    stub_external_calls

    expect(URI)
      .to(receive(:open)
            .with('.tar.gz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'raises an error when an unknown type is supplied' do
    define_task do |t|
      t.type = :wat
      t.uri_template = '<%= @ext %>'
    end
    set_platform
    stub_external_calls

    expect {
      Rake::Task['dependency:download'].invoke
    }.to raise_error(RuntimeError, 'Unknown type: wat')
  end

  it 'allows the distribution directory to be overridden' do
    define_task { |t| t.distribution_directory = 'spinach' }
    set_platform
    stub_external_calls

    expect_any_instance_of(subject)
      .to(receive(:mkdir_p)
            .with('vendor/dependency/spinach'))

    Rake::Task['dependency:download'].invoke
  end
end
