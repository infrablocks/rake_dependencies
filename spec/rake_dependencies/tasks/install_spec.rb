require 'spec_helper'

describe RakeDependencies::Tasks::Install do
  include_context :rake

  def define_task(*args, &block)
    namespace :dependency do
      subject.new(*args) do |t|
        t.dependency = 'some-dep'
        t.path = 'vendor/dependency'
        t.binary_name_template = 'some-dep-<%= @version %>'
        t.installation_directory = 'some/important/directory'
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

  context 'task definition' do
    it 'adds an install task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:install']).not_to be_nil
    end

    it 'gives the install task a description' do
      define_task { |t| t.dependency = 'the-thing' }

      expect(rake.last_description).to(eq('Install the-thing'))
    end

    it 'allows multiple install tasks to be declared ' do
      define_task { |t| t.name = 'install1' }
      define_task { |t| t.name = 'install2' }

      expect(Rake::Task['dependency:install1']).not_to be_nil
      expect(Rake::Task['dependency:install2']).not_to be_nil
    end
  end

  context 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(:copy)

      expect(Rake::Task['dependency:copy']).not_to be_nil
    end

    it 'passes a platform of :mac for a darwin platform' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('darwin')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/mac', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes a platform of :linux for all other platforms' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @platform %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/linux', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes an OS ID of "mac" for a :mac platform by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @os_id %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('darwin')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/mac', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes an OS ID of "linux" for a :linux platforms by default' do
      define_task { |t|
        t.path = 'some/path'
        t.binary_name_template = '<%= @os_id %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/linux', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided OS ID for a :mac platform when present' do
      define_task { |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.binary_name_template = '<%= @os_id %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('darwin')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/darwin', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'passes the provided OS ID for a :linux platform when present' do
      define_task { |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.binary_name_template = '<%= @os_id %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with('some/path/bin/linux64', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .zip when type is zip' do
      define_task do |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :zip
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/binary-from.zip', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .tgz when type is tgz' do
      define_task do |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :tgz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

      expect_any_instance_of(subject)
          .to(receive(:mkdir_p).with('somewhere/important'))
      expect_any_instance_of(subject)
          .to(receive(:cp).with(
              'some/path/bin/binary-from.tgz', 'somewhere/important'))

      Rake::Task['dependency:install'].invoke
    end

    it 'uses an extension of .tar.gz when type is tar_gz' do
      define_task do |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.type = :tar_gz
        t.binary_name_template = 'binary-from<%= @ext %>'
        t.installation_directory = 'somewhere/important'
      end
      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

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
        t.binary_name_template = '<%= @os_id %>'
        t.installation_directory = 'somewhere/important'
      }

      stub_cp
      stub_mkdir_p

      set_platform_to('linux')

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

      set_platform_to('linux')

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
