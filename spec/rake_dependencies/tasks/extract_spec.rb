# frozen_string_literal: true

require 'spec_helper'

describe RakeDependencies::Tasks::Extract do
  include_context 'rake'

  # rubocop:disable Metrics/MethodLength
  def define_task(opts = {}, &block)
    namespace :dependency do
      opts = {
        dependency: 'some-dep',
        type: :zip,
        path: 'vendor/dependency',
        version: '1.2.3',
        file_name_template:
          'some-dep-<%= @platform_os_name %>-<%= @platform_cpu_name %>' \
          '<%= @ext %>'
      }.merge(opts)
      subject.define(opts) do |t|
        block&.call(t)
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  # throws if required parameters are not supplied

  describe 'task definition' do
    it 'adds an extract task in the namespace in which it is created' do
      define_task

      expect(Rake.application)
        .to(have_task_defined('dependency:extract'))
    end

    it 'gives the extract task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:extract'].full_comment)
        .to(eq('Extract the-thing archive'))
    end

    it 'allows multiple extract tasks to be declared' do
      define_task(name: 'extract1')
      define_task(name: 'extract2')

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[dependency:extract1
                 dependency:extract2]
            ))
    end
  end

  describe 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :unarchive)

      expect(Rake.application)
        .to(have_task_defined('dependency:unarchive'))
    end

    it 'passes a platform CPU name of "amd64" for x86_64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x86_64-darwin')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/amd64', any_args))
    end

    it 'passes a platform CPU name of "amd64" for x64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/amd64', any_args))
    end

    it 'passes a platform CPU name of "386" for x86 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x86-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/386', any_args))
    end

    it 'passes a platform CPU name of "arm" for arm by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('arm-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/arm', any_args))
    end

    it 'passes a platform CPU name of "arm64" for arm64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('arm64-darwin-21')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/arm64', any_args))
    end

    it 'passes the provided platform CPU name for x86_64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { x86_64: 'x86_64' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x86_64-darwin')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/x86_64', any_args))
    end

    it 'passes the provided platform CPU name for x64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { x64: 'x86_64' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/x86_64', any_args))
    end

    it 'passes the provided platform CPU name for x86 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { x86: 'x86' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('x86-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/x86', any_args))
    end

    it 'passes the provided platform CPU name for arm when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { arm: 'armv4' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('arm-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/armv4', any_args))
    end

    it 'passes the provided platform CPU name for arm64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { arm64: 'armv9' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('arm64-darwin-21')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/armv9', any_args))
    end

    it 'passes the provided platform CPU name for another arch when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_cpu_names = { powerpc: 'powerpc' }
        t.file_name_template = '<%= @platform_cpu_name %>'
      end
      use_platform('powerpc-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/powerpc', any_args))
    end

    it 'passes a platform OS name of "darwin" on darwin by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('arm64-darwin-21')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/darwin', any_args))
    end

    it 'passes a platform OS name of "linux" on linux by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/linux', any_args))
    end

    it 'passes a platform OS name of "windows" on mswin32 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86-mswin32')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/windows', any_args))
    end

    it 'passes a platform OS name of "windows" on mswin64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86_64-mswin64')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/windows', any_args))
    end

    it 'passes the provided platform OS name for darwin when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_os_names = { darwin: 'mac' }
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86_64-darwin')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/mac', any_args))
    end

    it 'passes the provided platform OS name for linux when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_os_names = { linux: 'linux64' }
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/linux64', any_args))
    end

    it 'passes the provided platform OS name for mswin32 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_os_names = { mswin32: 'mswin32' }
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('i686-mswin32')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/mswin32', any_args))
    end

    it 'passes the provided platform OS name for mswin64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_os_names = { mswin64: 'mswin64' }
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x64-mswin64')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/mswin64', any_args))
    end

    it 'passes the provided platform OS name for another OS when present' do
      define_task do |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.platform_os_names = { aix: 'aix' }
        t.file_name_template = '<%= @platform_os_name %>'
      end
      use_platform('x86-aix')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('some/path/dist/aix', any_args))
    end

    it 'uses an extension of .zip when type is zip' do
      define_task do |t|
        t.type = :zip
        t.file_name_template = 'file<%= @ext %>'
      end
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('vendor/dependency/dist/file.zip', any_args))
    end

    it 'uses an extension of .tgz when type is tgz' do
      define_task do |t|
        t.type = :tgz
        t.file_name_template = 'file<%= @ext %>'
      end
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::TarGzExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::TarGzExtractor)
        .to(have_received(:new)
              .with('vendor/dependency/dist/file.tgz', any_args))
    end

    it 'uses an extension of .tar.gz when type is tar_gz' do
      define_task do |t|
        t.type = :tar_gz
        t.file_name_template = 'file<%= @ext %>'
      end
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::TarGzExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::TarGzExtractor)
        .to(have_received(:new)
              .with('vendor/dependency/dist/file.tar.gz', any_args))
    end

    it 'uses the provided platform specific extension when a map is passed ' \
       'as the type' do
      define_task do |t|
        t.type = { darwin: :zip, linux: :tar_gz }
        t.file_name_template = 'file<%= @ext %>'
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::TarGzExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::TarGzExtractor)
        .to(have_received(:new)
              .with('vendor/dependency/dist/file.tar.gz', any_args))
    end

    it 'allows the distribution directory to be overridden' do
      define_task do |t|
        t.distribution_directory = 'spinach'
      end
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with('vendor/dependency/spinach/some-dep-darwin-arm64.zip',
                    anything,
                    anything))
    end

    it 'allows the binary directory to be overridden' do
      define_task do |t|
        t.binary_directory = 'cabbage'
      end
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with(anything, 'vendor/dependency/cabbage', anything))
    end

    it 'raises an error when an unknown type is supplied' do
      define_task do |t|
        t.type = :wat
        t.file_name_template = '<%= @ext %>'
      end
      use_default_platform

      expect do
        Rake::Task['dependency:extract'].invoke
      end.to raise_error(RuntimeError, 'Unknown type: wat')
    end
  end

  describe 'zipped distributions' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the contents of the zip file to the extract path' do
      define_task { |t| t.type = :zip }
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor).to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with(
                'vendor/dependency/dist/some-dep-darwin-arm64.zip',
                'vendor/dependency/bin',
                anything
              ))
      expect(extractor).to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'tarred and gzipped distributions' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the contents of the tgz file to the extract path' do
      define_task { |t| t.type = :tar_gz }
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::TarGzExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::TarGzExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor).to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::TarGzExtractor)
        .to(have_received(:new)
              .with(
                'vendor/dependency/dist/some-dep-darwin-arm64.tar.gz',
                'vendor/dependency/bin',
                anything
              ))
      expect(extractor).to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'platform specific compressed distributions' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'uses the specified mac extractor when on a mac platform' do
      define_task do |t|
        t.type = {
          darwin: :zip,
          linux: :tar_gz
        }
      end
      use_platform('arm64-darwin-21')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor).to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with(
                'vendor/dependency/dist/some-dep-darwin-arm64.zip',
                'vendor/dependency/bin',
                anything
              ))
      expect(extractor).to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses the specified linux extractor when on a linux platform' do
      define_task do |t|
        t.type = {
          darwin: :zip,
          linux: :tar_gz
        }
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::TarGzExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::TarGzExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor).to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::TarGzExtractor)
        .to(have_received(:new)
              .with(
                'vendor/dependency/dist/some-dep-linux-amd64.tar.gz',
                'vendor/dependency/bin',
                anything
              ))
      expect(extractor).to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'uncompressed distributions' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'copies the uncompressed distribution to the binary directory with ' \
       'the supplied name' do
      define_task do |t|
        t.type = :uncompressed
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::UncompressedExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::UncompressedExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor).to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::UncompressedExtractor)
        .to(have_received(:new)
              .with(
                'vendor/dependency/dist/some-dep-linux-amd64',
                'vendor/dependency/bin',
                anything
              ))
      expect(extractor)
        .to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'extraction options' do
    it 'passes a strip path created using the supplied template when present' do
      define_task do |t|
        t.version = '0.1.0'
        t.strip_path_template =
          'strip/<%= @version %>-<%= @platform_os_name %>'
      end
      use_platform('x86_64-darwin')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with(anything, anything, { strip_path: 'strip/0.1.0-darwin' }))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the source and target binary names when present' do
      define_task do |t|
        t.type = :zip
        t.version = '1.2.3'
        t.source_binary_name_template = 'binary.<%= @version %>'
        t.target_binary_name_template = 'binary.<%= @platform_os_name %>'
      end
      use_platform('x86_64-linux')

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new).and_return(extractor))
      allow(extractor)
        .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke

      expect(RakeDependencies::Extractors::ZipExtractor)
        .to(have_received(:new)
              .with(
                anything,
                anything,
                { rename_from: 'binary.1.2.3', rename_to: 'binary.linux' }
              ))
      expect(extractor)
        .to(have_received(:extract))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'logging' do
    it 'logs on starting extract task' do
      dependency = 'some-cool-tool'
      logger = instance_double(Logger)

      define_task(dependency: dependency, type: :zip, logger: logger)
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expect(logger)
        .to(have_received(:info)
              .with("Extracting '#{dependency}'..."))
    end

    it 'logs resolved parameters' do
      version = '1.2.3'
      platform = 'arm64-darwin-21'
      logger = instance_double(Logger)

      define_task(
        version: version,
        type: :zip,
        logger: logger
      )
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expected_parameters = {
        version: version,
        platform: platform,
        platform_cpu_name: 'arm64',
        platform_os_name: 'darwin',
        ext: '.zip'
      }

      expect(logger)
        .to(have_received(:debug)
              .with("Using parameters: #{expected_parameters}."))
    end

    it 'logs resolved distribution file path' do
      path = 'vendor/some-dep'
      distribution_directory = 'dist'
      platform = 'arm64-darwin-21'
      file_name_template =
        'some-dep-<%= @platform_os_name %>-<%= @platform_cpu_name %>' \
        '<%= @ext %>'
      logger = instance_double(Logger)

      define_task(
        path: path,
        distribution_directory: distribution_directory,
        platform: platform,
        type: :zip,
        file_name_template: file_name_template,
        logger: logger
      )
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expected_distribution_file_path =
        'vendor/some-dep/dist/some-dep-darwin-arm64.zip'

      expect(logger)
        .to(have_received(:debug)
              .with('Using distribution file path: ' \
                    "#{expected_distribution_file_path}."))
    end

    it 'logs resolved extraction path' do
      path = 'vendor/some-dep'
      binary_directory = 'bin'
      logger = instance_double(Logger)

      define_task(
        path: path,
        binary_directory: binary_directory,
        logger: logger
      )
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expected_extraction_path =
        'vendor/some-dep/bin'

      expect(logger)
        .to(have_received(:debug)
              .with('Using extraction path: ' \
                    "#{expected_extraction_path}."))
    end

    it 'logs resolved extraction options' do
      version = '7.8.9'
      platform = 'arm64-darwin-21'
      strip_path_template = 'strip/<%= @version %>-<%= @platform_os_name %>'
      source_binary_name_template = 'binary.<%= @version %>'
      target_binary_name_template = 'binary.<%= @platform_os_name %>'
      logger = instance_double(Logger)

      define_task(
        version: version,
        strip_path_template: strip_path_template,
        source_binary_name_template: source_binary_name_template,
        target_binary_name_template: target_binary_name_template,
        logger: logger
      )
      use_platform(platform)

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expected_extraction_options = {
        strip_path: 'strip/7.8.9-darwin',
        rename_from: 'binary.7.8.9',
        rename_to: 'binary.darwin'
      }

      expect(logger)
        .to(have_received(:debug)
              .with('Using extraction options: ' \
                    "#{expected_extraction_options}."))
    end

    it 'logs on completing extract task' do
      dependency = 'some-cool-tool'
      logger = instance_double(Logger)

      define_task(dependency: dependency, type: :zip, logger: logger)
      use_default_platform

      extractor = instance_double(
        RakeDependencies::Extractors::ZipExtractor,
        extract: nil
      )

      allow(RakeDependencies::Extractors::ZipExtractor)
        .to(receive(:new)
              .and_return(extractor))

      stub_logger(logger)

      Rake::Task['dependency:extract'].invoke

      expect(logger)
        .to(have_received(:info)
              .with('Extracted.'))
    end
  end

  def stub_logger(logger)
    allow(logger).to(receive(:info))
    allow(logger).to(receive(:debug))
  end

  def use_platform(string)
    allow(Gem::Platform)
      .to(receive(:local)
            .and_return(Gem::Platform.new(string)))
  end

  def use_default_platform
    use_platform('arm64-darwin-21')
  end
end
