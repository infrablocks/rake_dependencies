# frozen_string_literal: true

require 'spec_helper'

describe RakeDependencies::Tasks::Install do
  include_context 'rake'

  # rubocop:disable Metrics/MethodLength
  def define_task(opts = {}, &block)
    namespace :dependency do
      opts = {
        dependency: 'some-dep',
        path: 'vendor/dependency',
        binary_name_template: 'some-dep-<%= @version %>',
        installation_directory: 'some/important/directory'
      }.merge(opts)
      subject.define(opts) do |t|
        block&.call(t)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  describe 'task definition' do
    it 'adds an install task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:install']).not_to be_nil
    end

    it 'gives the install task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:install'].full_comment)
        .to(eq('Install the-thing'))
    end

    it 'allows multiple install tasks to be declared' do
      define_task(name: 'install1')
      define_task(name: 'install2')

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[dependency:install1
                 dependency:install2]
            ))
    end
  end

  describe 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :copy)

      expect(Rake.application)
        .to(have_task_defined('dependency:copy'))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "amd64" for x86_64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-darwin')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/amd64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "amd64" for x64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/amd64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "386" for x86 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/386', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "arm" for arm by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('arm-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/arm', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "arm64" for arm64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('arm64-darwin-21')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/arm64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform CPU name of "aarch64" for aarch64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('aarch64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/aarch64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for x86_64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x86_64: 'x86_64' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end
      use_platform('x86_64-darwin')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/x86_64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for x64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x64: 'x86_64' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/x86_64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for x86 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x86: 'x86' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/x86', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for arm when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { arm: 'armv4' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('arm-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/armv4', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for arm64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { arm64: 'armv9' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('arm64-darwin-21')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/armv9', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for aarch64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { aarch64: 'armv9' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('aarch64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/armv9', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform CPU name for another arch when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_cpu_names = { powerpc: 'powerpc' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('powerpc-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/powerpc', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform OS name of "darwin" on darwin by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('arm64-darwin-21')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/darwin', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform OS name of "linux" on linux by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/linux', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform OS name of "windows" on mswin32 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86-mswin32')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/windows', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes a platform OS name of "windows" on mswin64 by default' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-mswin64')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/windows', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform OS name for darwin when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_os_names = { darwin: 'mac' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-darwin')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/mac', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform OS name for linux when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_os_names = { linux: 'linux64' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/linux64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform OS name for mswin32 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_os_names = { mswin32: 'mswin32' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('i686-mswin32')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/mswin32', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform OS name for mswin64 when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_os_names = { mswin64: 'mswin64' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x64-mswin64')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/mswin64', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'passes the provided platform OS name for another OS when present' do
      define_task do |t|
        t.path = 'some/path'
        t.platform_os_names = { aix: 'aix' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86-aix')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/aix', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses an extension of .zip when type is zip' do
      define_task do |t|
        t.platform_os_names = { darwin: 'darwin', linux: 'linux64' }
        t.path = 'some/path'
        t.type = :zip
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/binary-from.zip', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses an extension of .tgz when type is tgz' do
      define_task do |t|
        t.platform_os_names = { darwin: 'darwin', linux: 'linux64' }
        t.path = 'some/path'
        t.type = :tgz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/binary-from.tgz', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'uses an extension of .tar.gz when type is tar_gz' do
      define_task do |t|
        t.platform_os_names = { darwin: 'darwin', linux: 'linux64' }
        t.path = 'some/path'
        t.type = :tar_gz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/binary-from.tar.gz', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the binary directory to be overridden' do
      define_task do |t|
        t.path = 'some/path'
        t.binary_directory = 'binaries'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/binaries/linux', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows the version to be interpolated' do
      define_task do |t|
        t.path = 'some/path'
        t.version = '1.2.3'
        t.binary_name_template = '<%= @version %>'
        t.installation_directory = 'somewhere/important'
      end

      use_platform('x86_64-linux')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      task.invoke

      expect(task.creator)
        .to(have_received(:mkdir_p)
              .with('somewhere/important'))
      expect(task.creator)
        .to(have_received(:cp)
              .with('some/path/bin/1.2.3', 'somewhere/important'))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'logging' do
    it 'logs on starting install task' do
      dependency = 'dependency'
      logger = instance_double(Logger)

      define_task(logger: logger, dependency: dependency)
      use_platform('x86_64-darwin')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      stub_logger(logger)

      task.invoke

      expect(logger)
        .to(have_received(:info)
              .with("Installing 'dependency'..."))
    end

    it 'logs resolved parameters' do
      version = '1.2.3'
      platform = 'arm64-darwin-21'
      logger = instance_double(Logger)

      define_task(
        logger: logger,
        version: version,
        type: :zip
      )
      use_platform(platform)

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      stub_logger(logger)

      task.invoke

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

    it 'logs resolved binary file path' do
      version = '1.2.3'
      platform = 'arm64-darwin-21'
      path = 'vendor/some-dep'
      binary_name_template = 'some-dep-<%= @version %>'
      logger = instance_double(Logger)

      define_task(
        version: version,
        path: path,
        binary_name_template: binary_name_template,
        logger: logger
      )
      use_platform(platform)

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      stub_logger(logger)

      task.invoke

      expected_binary_file_path = 'vendor/some-dep/bin/some-dep-1.2.3'

      expect(logger)
        .to(have_received(:debug)
              .with('Using binary file path: ' \
                    "#{expected_binary_file_path}."))
    end

    it 'logs installation directory' do
      installation_directory = 'some/important/directory'
      logger = instance_double(Logger)

      define_task(
        installation_directory: installation_directory,
        logger: logger
      )
      use_default_platform

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      stub_logger(logger)

      task.invoke

      expect(logger)
        .to(have_received(:debug)
              .with('Using installation directory: ' \
                    "#{installation_directory}."))
    end

    it 'logs on completing install task' do
      dependency = 'dependency'
      logger = instance_double(Logger)

      define_task(logger: logger, dependency: dependency)
      use_platform('x86_64-darwin')

      task = Rake::Task['dependency:install']

      allow(task.creator).to(receive(:mkdir_p))
      allow(task.creator).to(receive(:cp))

      stub_logger(logger)

      task.invoke

      expect(logger)
        .to(have_received(:info)
              .with('Installed.'))
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
