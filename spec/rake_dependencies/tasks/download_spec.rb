require 'spec_helper'

def stub_external_calls
  stub_open_uri
  stub_make_directory
  stub_copy
end

describe RakeDependencies::Tasks::Download do
  include_context :rake

  def define_task(*args, &block)
    namespace :dependency do
      subject.new(*args) do |t|
        t.path = 'vendor/dependency'
        t.dependency = 'super-cool-tool'
        t.version = '1.2.3'
        t.type = :tar_gz
        t.uri_template = 'https://example.com/<%= @version %>/super-cool-tool-<%= @os %>-x86_64<%= @ext %>'
        t.file_name_template = 'super-cool-tool-<%= @os %><%= @ext %>'
        block.call(t) if block
      end
    end
  end

  def set_platform_to(string)
    stub_const('RUBY_PLATFORM', string)
  end

  def set_platform
    set_platform_to('darwin')
  end

  def stub_open_uri
    File.open('/tmp_file', 'w') { |f| f.write('content') }
    allow_any_instance_of(subject).to(receive(:open).and_return(File.new('/tmp_file')))
  end

  def stub_make_directory
    allow_any_instance_of(subject).to(receive(:mkdir_p))
  end

  def stub_copy
    allow_any_instance_of(subject).to(receive(:cp))
  end

  it 'adds a download task in the namespace in which it is created' do
    define_task

    expect(Rake::Task['dependency:download']).not_to be_nil
  end

  it 'gives the download task a description' do
    define_task { |t| t.dependency = 'the-thing' }

    expect(rake.last_description).to(eq('Download the-thing distribution'))
  end

  it 'allows the task name to be overridden' do
    define_task(:fetch)

    expect(Rake::Task['dependency:fetch']).not_to be_nil
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
    set_platform_to('darwin')
    stub_external_calls

    expect_any_instance_of(subject)
        .to(receive(:open)
                .with('https://example.com/1.2.3/super-cool-tool-mac-x86_64.tar.gz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'copies the downloaded file to the download path using the download file name template' do
    define_task
    set_platform_to('darwin')
    stub_external_calls

    File.open('/download_file', 'w') { |f| f.write('download_content') }
    allow_any_instance_of(subject)
        .to(receive(:open)
                .and_return(File.new('/download_file')))

    expect_any_instance_of(subject)
        .to(receive(:cp)
                .with('/download_file', 'vendor/dependency/dist/super-cool-tool-mac.tar.gz'))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses an OS of linux for a non-darwin platform' do
    define_task { |t| t.uri_template = '<%= @os %>'}
    set_platform_to('something-weird')
    stub_external_calls

    expect_any_instance_of(subject)
        .to(receive(:open)
                .with('linux'))

    Rake::Task['dependency:download'].invoke
  end

  it 'uses an extension of .zip when type is zip' do
    define_task do |t|
      t.type = :zip
      t.uri_template = '<%= @ext %>'
    end
    set_platform
    stub_external_calls

    expect_any_instance_of(subject)
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

    expect_any_instance_of(subject)
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

    expect_any_instance_of(subject)
        .to(receive(:open)
                .with(''))

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

  it 'allows the download directory to be overidden' do
    define_task { |t| t.directory = 'spinach'}
    set_platform
    stub_external_calls

    expect_any_instance_of(subject)
        .to(receive(:mkdir_p)
                .with('vendor/dependency/spinach'))

    Rake::Task['dependency:download'].invoke
  end
end
