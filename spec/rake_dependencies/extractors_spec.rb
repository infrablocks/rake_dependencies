# frozen_string_literal: true

require 'spec_helper'
require 'zip'
require 'zlib'
require 'archive/tar/minitar'
require 'fileutils'
require 'fakefs/spec_helpers'

ZipExtractor = RakeDependencies::Extractors::ZipExtractor
TarGzExtractor = RakeDependencies::Extractors::TarGzExtractor
UncompressedExtractor = RakeDependencies::Extractors::UncompressedExtractor

describe RakeDependencies::Extractors do
  include ::FakeFS::SpecHelpers

  context ZipExtractor do
    it 'recursively makes the extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      stub_zip_file_open
      stub_make_directory

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with(extract_path))
    end

    it 'opens the zip file at the provided path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      stub_zip_file_open
      stub_make_directory

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      allow(Zip::File).to(receive(:open))

      extractor.extract

      expect(Zip::File)
        .to(have_received(:open)
              .with(zip_file_path))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'recursively makes directories for the zip file entries under the '\
       'extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      entry1 = build_zip_entry_for('directory/containing1/file1')
      entry2 = build_zip_entry_for('directory/containing2/file2')
      entry3 = build_zip_entry_for('file3')

      stub_make_directory
      stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/directory/containing1'))
      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/directory/containing2'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the entry into the extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      entry1 = build_zip_entry_for('directory/containing1/file1')
      entry2 = build_zip_entry_for('directory/containing2/file2')
      entry3 = build_zip_entry_for('file3')

      stub_make_directory
      zip_file = stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      allow(zip_file).to(receive(:extract))

      extractor.extract

      expect(zip_file)
        .to(have_received(:extract)
              .with(entry1, File.join(extract_path, entry1.name)))
      expect(zip_file)
        .to(have_received(:extract)
              .with(entry2, File.join(extract_path, entry2.name)))
      expect(zip_file)
        .to(have_received(:extract)
              .with(entry3, File.join(extract_path, entry3.name)))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'does not extract the entry into the extract path if a file already '\
       'exists at that location' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      existing_entry_path = 'directory/containing1/file1'
      existing_entry = build_zip_entry_for(existing_entry_path)

      zip_file = stub_zip_file_open_for(existing_entry)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      full_entry_path = File.join(extract_path, existing_entry_path)
      FileUtils.mkdir_p(File.dirname(full_entry_path))
      File.write(full_entry_path, "I'm here")

      allow(zip_file).to(receive(:extract))

      extractor.extract

      expect(zip_file)
        .not_to(have_received(:extract)
                  .with(existing_entry,
                        File.join(extract_path, existing_entry.name)))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'recursively makes directories for the stripped zip file entries '\
       'when a strip path option is supplied' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'
      options = { strip_path: 'useless/directory' }

      entry1_path = 'useless/directory/containing1/file1'
      entry2_path = 'useless/directory/containing2/file2'
      entry3_path = 'useless/directory/file3'

      entry1 = build_zip_entry_for(entry1_path)
      entry2 = build_zip_entry_for(entry2_path)
      entry3 = build_zip_entry_for(entry3_path)

      stub_make_directory
      stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path, options)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/containing1'))
      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/containing2'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the entry into the stripped extract path when a strip path '\
       'option is supplied' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'
      options = { strip_path: 'useless/directory' }

      entry1_path = 'useless/directory/containing1/file1'
      entry2_path = 'useless/directory/containing2/file2'
      entry3_path = 'useless/directory/file3'

      entry1 = build_zip_entry_for(entry1_path)
      entry2 = build_zip_entry_for(entry2_path)
      entry3 = build_zip_entry_for(entry3_path)

      stub_make_directory
      zip_file = stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path, options)

      allow(zip_file).to(receive(:extract))

      extractor.extract

      expect(zip_file)
        .to(have_received(:extract)
              .with(entry1, File.join(extract_path, 'containing1/file1')))
      expect(zip_file)
        .to(have_received(:extract)
              .with(entry2, File.join(extract_path, 'containing2/file2')))
      expect(zip_file)
        .to(have_received(:extract)
              .with(entry3, File.join(extract_path, 'file3')))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'renames the resulting binary when rename from and to are specified' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      entry1 = build_zip_entry_for('directory/containing1/file1')
      entry2 = build_zip_entry_for('directory/containing2/file2')
      entry3 = build_zip_entry_for('file3')

      stub_make_directory
      stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(
        zip_file_path, extract_path,
        {
          rename_from: 'directory/containing1/file1',
          rename_to: 'some/path/the-binary'
        }
      )

      allow(FileUtils).to(receive(:mkdir_p))
      allow(FileUtils).to(receive(:mv))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with(File.join(extract_path, 'some/path')))
      expect(FileUtils)
        .to(have_received(:mv)
              .with(
                File.join(extract_path, 'directory/containing1/file1'),
                File.join(extract_path, 'some/path/the-binary')
              ))
    end
    # rubocop:enable RSpec/MultipleExpectations

    def stub_zip_file_open
      stub_zip_file_open_for
    end

    def build_zip_entry_for(entry_path)
      entry = instance_double(Zip::Entry)
      allow(entry)
        .to(receive(:name)
              .and_return(entry_path))
      entry
    end

    def stub_zip_file_open_for(*entries)
      zip_file_entries = instance_double(Zip::File)

      stub_archive_file_each(entries, zip_file_entries)
      allow(zip_file_entries).to(receive(:extract))
      allow(zip_file_entries).to(receive(:restore_permissions=).with(true))
      allow(Zip::File).to(receive(:open).and_yield(zip_file_entries))

      zip_file_entries
    end
  end

  context TarGzExtractor do
    it 'recursively makes the extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_gzip_file_open
      stub_tar_file_open

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with(extract_path))
    end

    it 'decompresses the tgz file at the provided path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_gzip_file_open
      stub_tar_file_open

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      allow(Zlib::GzipReader).to(receive(:open))

      extractor.extract

      expect(Zlib::GzipReader)
        .to(have_received(:open)
              .with(tgz_file_path))
    end

    it 'opens the resulting tar file' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      tar_file = stub_gzip_file_open
      stub_tar_file_open
      stub_make_directory

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      allow(Archive::Tar::Minitar).to(receive(:open))

      extractor.extract

      expect(Archive::Tar::Minitar)
        .to(have_received(:open)
              .with(tar_file))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'recursively makes directories for the tgz file entries under the '\
       'extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      entry1 = build_tar_entry_for('directory/containing1/file1')
      entry2 = build_tar_entry_for('directory/containing2/file2')
      entry3 = build_tar_entry_for('file3')

      stub_gzip_file_open
      stub_make_directory
      stub_file_open
      stub_tar_file_open_for(entry1, entry2, entry3)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/directory/containing1'))
      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/directory/containing2'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the entry into the extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      entry1 = build_tar_entry_for(
        'directory', file: false, mode: 755
      )
      entry2 = build_tar_entry_for(
        'directory/containing1', file: false, mode: 755
      )
      entry3 = build_tar_entry_for(
        'directory/containing1/file1',
        file: true, mode: 644, contents: 'File1'
      )
      entry4 = build_tar_entry_for(
        'directory/containing2', file: false, mode: 755
      )
      entry5 = build_tar_entry_for(
        'directory/containing2/file2',
        file: true, mode: 644, contents: 'File2'
      )
      entry6 = build_tar_entry_for(
        'file3', file: true, mode: 644, contents: 'File3'
      )

      stub_gzip_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)
      extractor.extract

      expect(
        File.read('some/path/for/extraction/directory/containing1/file1')
      ).to(eq('File1'))
      expect(
        File.read('some/path/for/extraction/directory/containing2/file2')
      ).to(eq('File2'))
      expect(
        File.read('some/path/for/extraction/file3')
      ).to(eq('File3'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'does not extract the entry if a file already exists at the '\
       'extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      existing_entry_path = 'directory/containing1/file1'
      existing_entry = build_tar_entry_for(
        existing_entry_path, file: true, mode: 644, contents: 'File1'
      )

      stub_gzip_file_open
      stub_tar_file_open_for(existing_entry)

      full_entry_path = File.join(extract_path, existing_entry_path)
      FileUtils.mkdir_p(File.dirname(full_entry_path))
      File.write(full_entry_path, 'Existing')

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)
      extractor.extract

      expect(File.read(full_entry_path)).to eq('Existing')
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'recursively makes directories for the stripped tgz file entries '\
       'when a strip path option is supplied' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'
      options = { strip_path: 'useless/directory' }

      entry1 = build_tar_entry_for(
        'useless/directory/containing1/file1'
      )
      entry2 = build_tar_entry_for(
        'useless/directory/containing2/file2'
      )
      entry3 = build_tar_entry_for(
        'useless/directory/file3'
      )

      stub_gzip_file_open
      stub_make_directory
      stub_file_open
      stub_tar_file_open_for(entry1, entry2, entry3)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path, options)

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/containing1'))
      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction/containing2'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'extracts the entry into the stripped extract path when a strip '\
       'path option is supplied' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'
      options = { strip_path: 'useless/directory' }

      entry1 = build_tar_entry_for(
        'useless/directory',
        file: false, mode: 755
      )
      entry2 = build_tar_entry_for(
        'useless/directory/containing1',
        file: false, mode: 755
      )
      entry3 = build_tar_entry_for(
        'useless/directory/containing1/file1',
        file: true, mode: 644, contents: 'File1'
      )
      entry4 = build_tar_entry_for(
        'useless/directory/containing2', file: false, mode: 755
      )
      entry5 = build_tar_entry_for(
        'useless/directory/containing2/file2',
        file: true, mode: 644, contents: 'File2'
      )
      entry6 = build_tar_entry_for(
        'useless/directory/file3',
        file: true, mode: 644, contents: 'File3'
      )

      stub_gzip_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path, options)
      extractor.extract

      expect(File.read('some/path/for/extraction/containing1/file1'))
        .to(eq('File1'))
      expect(File.read('some/path/for/extraction/containing2/file2'))
        .to(eq('File2'))
      expect(File.read('some/path/for/extraction/file3'))
        .to(eq('File3'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'renames the resulting binary when rename from and to are specified' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      entry1 = build_tar_entry_for('directory',
                                   file: false, mode: 755)
      entry2 = build_tar_entry_for('directory/containing1',
                                   file: false, mode: 755)
      entry3 = build_tar_entry_for('directory/containing1/file1',
                                   file: true, mode: 644, contents: 'File1')
      entry4 = build_tar_entry_for('directory/containing2',
                                   file: false, mode: 755)
      entry5 = build_tar_entry_for('directory/containing2/file2',
                                   file: true, mode: 644, contents: 'File2')
      entry6 = build_tar_entry_for('file3',
                                   file: true, mode: 644, contents: 'File3')

      stub_gzip_file_open
      stub_make_directory
      stub_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(
        tgz_file_path, extract_path,
        {
          rename_from: 'directory/containing1/file1',
          rename_to: 'some/path/the-binary'
        }
      )

      allow(FileUtils).to(receive(:mkdir_p))
      allow(FileUtils).to(receive(:mv))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with(File.join(extract_path, 'some/path')))
      expect(FileUtils)
        .to(have_received(:mv)
              .with(
                File.join(extract_path, 'directory/containing1/file1'),
                File.join(extract_path, 'some/path/the-binary')
              ))
    end
    # rubocop:enable RSpec/MultipleExpectations

    def stub_gzip_file_open
      tar_file = instance_double(Zlib::GzipReader)
      allow(Zlib::GzipReader).to(receive(:open).and_yield(tar_file))
      tar_file
    end

    def build_tar_entry_for(
      entry_path,
      options = {}
    )
      options = { file: true, mode: 644, contents: 'Content' }.merge(options)

      instance_double(
        Archive::Tar::Minitar::Reader::EntryStream,
        name: entry_path,
        file?: options[:file],
        mode: options[:mode],
        read: options[:contents]
      )
    end

    def stub_tar_file_open
      stub_tar_file_open_for
    end

    def stub_tar_file_open_for(*entries)
      tar_file_entries = instance_double(Archive::Tar::Minitar::Input)

      stub_archive_file_each(entries, tar_file_entries)
      allow(Archive::Tar::Minitar)
        .to(receive(:open)
              .and_yield(tar_file_entries))

      tar_file_entries
    end

    def stub_file_open
      allow(File).to(receive(:open))
    end
  end

  context RakeDependencies::Extractors::UncompressedExtractor do
    def stub_copy_file
      allow(FileUtils).to(receive(:cp))
    end

    def stub_chmod_file
      allow(FileUtils).to(receive(:chmod))
    end

    it 'recursively makes the target path' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(
        uncompressed_file_path, extract_path
      )

      allow(FileUtils).to(receive(:mkdir_p))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:mkdir_p)
              .with('some/path/for/extraction'))
    end

    it 'copies the binary to the target path' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(
        uncompressed_file_path, extract_path
      )

      allow(FileUtils).to(receive(:cp))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:cp)
              .with(uncompressed_file_path,
                    'some/path/for/extraction/the-file'))
    end

    it 'renames the binary when the rename_from and rename_to options '\
       'are provided' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'
      options = { rename_to: 'other-file' }

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(
        uncompressed_file_path, extract_path, options
      )

      allow(FileUtils).to(receive(:cp))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:cp)
              .with(uncompressed_file_path,
                    'some/path/for/extraction/other-file'))
    end

    it 'makes the target file executable' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(uncompressed_file_path,
                                            extract_path)

      allow(FileUtils).to(receive(:chmod))

      extractor.extract

      expect(FileUtils)
        .to(have_received(:chmod)
              .with(0o755, 'some/path/for/extraction/the-file'))
    end
  end

  def stub_make_directory
    allow(FileUtils).to(receive(:mkdir_p))
  end

  def stub_archive_file_each(entries, archive)
    receive_entries = entries.reduce(receive(:each)) do |receiver, entry|
      receiver.and_yield(entry)
    end

    allow(archive).to(receive_entries)
  end
end
