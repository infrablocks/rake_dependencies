require 'spec_helper'

describe RakeDependencies::Tasks::Extract do
  include_context :rake

  def define_task(opts = {}, &block)
    namespace :dependency do
      subject.define({dependency: 'some-dep'}.merge(opts)) do |t|
        t.type = :zip
        t.path = 'vendor/dependency'
        t.version = '1.2.3'
        t.file_name_template = 'some-dep-<%= @os_id %><%= @ext %>'
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
    it 'adds an extract task in the namespace in which it is created' do
      define_task

      expect(Rake::Task['dependency:extract']).not_to be_nil
    end

    it 'gives the extract task a description' do
      define_task(dependency: 'the-thing')

      expect(Rake::Task['dependency:extract'].full_comment)
          .to(eq('Extract the-thing archive'))
    end

    it 'allows multiple extract tasks to be declared' do
      define_task(name: 'extract1')
      define_task(name: 'extract2')

      expect(Rake::Task['dependency:extract1']).not_to be_nil
      expect(Rake::Task['dependency:extract2']).not_to be_nil
    end
  end

  context 'parameters' do
    it 'allows the task name to be overridden' do
      define_task(name: :unarchive)

      expect(Rake::Task['dependency:unarchive']).not_to be_nil
    end

    it 'passes a platform of :mac for a darwin platform' do
      define_task { |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform %>'
      }
      set_platform_to('darwin')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/mac', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes a platform of :linux for all other platforms' do
      define_task { |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @platform %>'
      }
      set_platform_to('linux')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/linux', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes an OS ID of "mac" for a :mac platform by default' do
      define_task { |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @os_id %>'
      }
      set_platform_to('darwin')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/mac', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes an OS ID of "linux" for a :linux platform by default' do
      define_task { |t|
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @os_id %>'
      }
      set_platform_to('linux')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/linux', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes the provided OS ID for a :mac platform when present' do
      define_task { |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @os_id %>'
      }
      set_platform_to('darwin')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/darwin', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes the provided OS ID for a :linux platform when present' do
      define_task { |t|
        t.os_ids = {mac: 'darwin', linux: 'linux64'}
        t.path = 'some/path'
        t.distribution_directory = 'dist'
        t.file_name_template = '<%= @os_id %>'
      }
      set_platform_to('linux')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('some/path/dist/linux64', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'uses an extension of .zip when type is zip' do
      define_task do |t|
        t.type = :zip
        t.file_name_template = 'file<%= @ext %>'
      end
      set_platform

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('vendor/dependency/dist/file.zip', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'uses an extension of .tgz when type is tgz' do
      define_task do |t|
        t.type = :tgz
        t.file_name_template = 'file<%= @ext %>'
      end
      set_platform

      extractor = double('tgz extractor', extract: nil)

      expect(RakeDependencies::Extractors::TarGzExtractor)
          .to(receive(:new)
                  .with('vendor/dependency/dist/file.tgz', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'uses an extension of .tar.gz when type is tar_gz' do
      define_task do |t|
        t.type = :tar_gz
        t.file_name_template = 'file<%= @ext %>'
      end
      set_platform

      extractor = double('tgz extractor', extract: nil)

      expect(RakeDependencies::Extractors::TarGzExtractor)
          .to(receive(:new)
                  .with('vendor/dependency/dist/file.tar.gz', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'uses the provided platform specific extension when a map is passed as the type' do
      define_task do |t|
        t.type = {mac: :zip, linux: :tar_gz}
        t.file_name_template = 'file<%= @ext %>'
      end
      set_platform_to('linux')

      extractor = double('tgz extractor', extract: nil)

      expect(RakeDependencies::Extractors::TarGzExtractor)
          .to(receive(:new)
                  .with('vendor/dependency/dist/file.tar.gz', any_args)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'allows the distribution directory to be overridden' do
      define_task { |t|
        t.distribution_directory = 'spinach'
      }
      set_platform

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with('vendor/dependency/spinach/some-dep-mac.zip', anything, anything)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'allows the binary directory to be overridden' do
      define_task { |t|
        t.binary_directory = 'cabbage'
      }
      set_platform

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with(anything, 'vendor/dependency/cabbage', anything)
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'raises an error when an unknown type is supplied' do
      define_task do |t|
        t.type = :wat
        t.file_name_template = '<%= @ext %>'
      end
      set_platform

      expect {
        Rake::Task['dependency:extract'].invoke
      }.to raise_error(RuntimeError, 'Unknown type: wat')
    end
  end

  context 'zipped distributions' do
    it 'extracts the contents of the zip file to the extract path' do
      define_task { |t| t.type = :zip }
      set_platform

      extractor = double('zip extractor')

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with(
                      'vendor/dependency/dist/some-dep-mac.zip',
                      'vendor/dependency/bin',
                      anything)
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end
  end

  context 'tarred and gzipped distributions' do
    it 'extracts the contents of the tgz file to the extract path' do
      define_task { |t| t.type = :tar_gz }
      set_platform

      extractor = double('tgz extractor')

      expect(RakeDependencies::Extractors::TarGzExtractor)
          .to(receive(:new)
                  .with(
                      'vendor/dependency/dist/some-dep-mac.tar.gz',
                      'vendor/dependency/bin',
                      anything)
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end
  end

  context 'platform specific compressed distributions' do
    it 'uses the specified mac extractor when on a mac platform' do
      define_task do |t|
        t.type = {
            mac: :zip,
            linux: :tar_gz
        }
      end
      set_platform_to('darwin')

      extractor = double('zip extractor')

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with(
                      'vendor/dependency/dist/some-dep-mac.zip',
                      'vendor/dependency/bin',
                      anything)
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end

    it 'uses the specified linux extractor when on a linux platform' do
      define_task do |t|
        t.type = {
            mac: :zip,
            linux: :tar_gz
        }
      end
      set_platform_to('linux')

      extractor = double('tgz extractor')

      expect(RakeDependencies::Extractors::TarGzExtractor)
          .to(receive(:new)
                  .with(
                      'vendor/dependency/dist/some-dep-linux.tar.gz',
                      'vendor/dependency/bin',
                      anything)
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end
  end

  context 'uncompressed distributions' do
    it 'copies the uncompressed distribution to the binary directory with the supplied name' do
      define_task do |t|
        t.type = :uncompressed
      end
      set_platform_to('linux')

      extractor = double('tgz extractor')

      expect(RakeDependencies::Extractors::UncompressedExtractor)
          .to(receive(:new)
                  .with(
                      'vendor/dependency/dist/some-dep-linux',
                      'vendor/dependency/bin',
                      anything)
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end
  end

  context 'extraction options' do
    it 'passes a strip path created using the supplied template when present' do
      define_task do |t|
        t.version = '0.1.0'
        t.strip_path_template = "strip/<%= @version %>-<%= @os_id %>"
      end
      set_platform_to('darwin')

      extractor = double('zip extractor', extract: nil)

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with(anything, anything, { strip_path: 'strip/0.1.0-mac' })
                  .and_return(extractor))

      Rake::Task['dependency:extract'].invoke
    end

    it 'passes the source and target binary names when present' do
      define_task do |t|
        t.type = :zip
        t.version = '1.2.3'
        t.source_binary_name_template = 'binary.<%= @version %>'
        t.target_binary_name_template = 'binary.<%= @os_id %>'
      end
      set_platform_to('linux')

      extractor = double('zip extractor')

      expect(RakeDependencies::Extractors::ZipExtractor)
          .to(receive(:new)
                  .with(
                      anything,
                      anything,
                      {rename_from: 'binary.1.2.3', rename_to: 'binary.linux'})
                  .and_return(extractor))
      expect(extractor)
          .to(receive(:extract))

      Rake::Task['dependency:extract'].invoke
    end
  end

  # throws if required parameters are not supplied
end
