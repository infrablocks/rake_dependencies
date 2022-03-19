require 'spec_helper'

describe RakeDependencies::Tasks::Install do
  include_context :rake

  def define_task(opts = {}, &block)
    namespace :dependency do
      subject.define({dependency: 'some-dep'}.merge(opts)) do |t|
        t.path = 'vendor/dependency'
        t.binary_name_template = 'some-dep-<%= @version %>'
        t.installation_directory = 'some/important/directory'
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

  context 'task definition' do
    it 'adds an install task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:install']).not_to be_nil
    end

    it 'gives the install task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:install'].full_comment)
          .to(eq('Install the-thing'))
    end

    it 'allows multiple install tasks to be declared ' do
      define_task(name: 'install1')
      define_task(name: 'install2')

      expect(Rake::Task['dependency:install1']).not_to be_nil
      expect(Rake::Task['dependency:install2']).not_to be_nil
    end
  end

  context 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :copy)

      expect(Rake::Task['dependency:copy']).not_to be_nil
    end

    it 'passes a platform CPU name of "amd64" for x86_64 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-darwin')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/amd64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform CPU name of "amd64" for x64 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x64-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/amd64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform CPU name of "386" for x86 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/386', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform CPU name of "arm" for arm by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('arm-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/arm', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform CPU name of "arm64" for arm64 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('arm64-darwin-21')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/arm64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for x86_64 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x86_64: 'x86_64' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-darwin')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/x86_64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for x64 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x64: 'x86_64' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x64-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/x86_64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for x86 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { x86: 'x86' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/x86', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for arm when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { arm: 'armv4' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('arm-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/armv4', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for arm64 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { arm64: 'armv9' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('arm64-darwin-21')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/armv9', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform CPU name for another arch when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_cpu_names = { powerpc: 'powerpc' }
        t.binary_name_template = '<%= @platform_cpu_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('powerpc-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/powerpc', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform OS name of "darwin" on darwin by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('arm64-darwin-21')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/darwin', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform OS name of "linux" on linux by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/linux', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform OS name of "windows" on mswin32 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86-mswin32')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/windows', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform OS name of "windows" on mswin64 by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-mswin64')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/windows', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform OS name for darwin when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_os_names = { darwin: 'mac' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-darwin')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/mac', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform OS name for linux when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_os_names = { linux: 'linux64' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/linux64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform OS name for mswin32 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_os_names = { mswin32: 'mswin32' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('i686-mswin32')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/mswin32', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform OS name for mswin64 when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_os_names = { mswin64: 'mswin64' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x64-mswin64')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/mswin64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided platform OS name for another OS when present' do
      define_task { |t|
        t.path = 'some/path'
        t.platform_os_names = { aix: 'aix' }
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86-aix')

      expect_any_instance_of(subject)
        .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
        .to(receive(:cp).with('some/path/bin/aix', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .zip when type is zip' do
      define_task do |t|
        t.platform_os_names = {darwin: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :zip
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/binary-from.zip', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .tgz when type is tgz' do
      define_task do |t|
        t.platform_os_names = {darwin: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :tgz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/binary-from.tgz', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .tar.gz when type is tar_gz' do
      define_task do |t|
        t.platform_os_names = {darwin: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :tar_gz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/binary-from.tar.gz', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'allows the binary directory to be overridden' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_directory = 'binaries'
        t.binary_name_template = '<%= @platform_os_name %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/binaries/linux', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'allows the version to be interpolated' do
      define_task { |t|
        t.path = 'some/path'
        t.version = '1.2.3'
        t.binary_name_template = '<%= @version %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('x86_64-linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/1.2.3', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end
  end

  def stub_cp
    allow_any_instance_of(FileUtils).to(receive(:cp))
  end

  def stub_mkdir_p
    allow_any_instance_of(FileUtils).to(receive(:mkdir_p))
  end
end
