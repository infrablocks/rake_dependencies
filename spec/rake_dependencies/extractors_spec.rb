require 'spec_helper'
require 'zip'
require 'zlib'
require 'archive/tar/minitar'
require 'fileutils'
require 'fakefs/spec_helpers'

describe RakeDependencies::Extractors do
  include ::FakeFS::SpecHelpers

  ZipExtractor = RakeDependencies::Extractors::ZipExtractor
  TarGzExtractor = RakeDependencies::Extractors::TarGzExtractor
  UncompressedExtractor = RakeDependencies::Extractors::UncompressedExtractor

  def stub_make_directory
    allow(FileUtils).to(receive(:mkdir_p))
  end

  context RakeDependencies::Extractors::ZipExtractor do
    def stub_zip_file_open
      stub_zip_file_open_for
    end

    def build_zip_entry_for(entry_path)
      entry = double(entry_path)
      allow(entry).to(receive(:name).and_return(entry_path))
      entry
    end

    def stub_zip_file_open_for(*entries)
      zip_file_entries = double('zip file entries')

      receive_entries = entries.reduce(receive(:each)) do |receiver, entry|
        receiver.and_yield(entry)
      end

      allow(zip_file_entries).to(receive_entries)
      allow(zip_file_entries).to(receive(:extract))
      allow(Zip::File).to(receive(:open).and_yield(zip_file_entries))

      zip_file_entries
    end

    it 'recursively makes the extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      stub_zip_file_open
      stub_make_directory

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      expect(FileUtils).to(receive(:mkdir_p).with(extract_path))

      extractor.extract
    end

    it 'opens the zip file at the provided path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      stub_zip_file_open
      stub_make_directory

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      expect(Zip::File).to(receive(:open).with(zip_file_path))

      extractor.extract
    end

    it 'recursively makes directories for the zip file entries under the extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      entry1 = build_zip_entry_for('directory/containing1/file1')
      entry2 = build_zip_entry_for('directory/containing2/file2')
      entry3 = build_zip_entry_for('file3')

      stub_make_directory
      stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/directory/containing1'))
      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/directory/containing2'))

      extractor.extract
    end

    it 'extracts the entry into the extract path' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      entry1 = build_zip_entry_for('directory/containing1/file1')
      entry2 = build_zip_entry_for('directory/containing2/file2')
      entry3 = build_zip_entry_for('file3')

      stub_make_directory
      zip_file = stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      expect(zip_file).to(receive(:extract).with(entry1, File.join(extract_path, entry1.name)))
      expect(zip_file).to(receive(:extract).with(entry2, File.join(extract_path, entry2.name)))
      expect(zip_file).to(receive(:extract).with(entry3, File.join(extract_path, entry3.name)))

      extractor.extract
    end

    it 'does not extract the entry into the extract path if a file already exists at that location' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'

      existing_entry_path = 'directory/containing1/file1'
      existing_entry = build_zip_entry_for(existing_entry_path)

      zip_file = stub_zip_file_open_for(existing_entry)

      extractor = ZipExtractor.new(zip_file_path, extract_path)

      full_entry_path = File.join(extract_path, existing_entry_path)
      FileUtils.mkdir_p(File.dirname(full_entry_path))
      File.open(full_entry_path, 'w') {|f| f.write("I'm here")}

      expect(zip_file).not_to(receive(:extract).with(existing_entry, File.join(extract_path, existing_entry.name)))

      extractor.extract
    end

    it 'recursively makes directories for the stripped zip file entries when a strip path option is supplied' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'
      options = {strip_path: 'useless/directory'}

      entry1_path = 'useless/directory/containing1/file1'
      entry2_path = 'useless/directory/containing2/file2'
      entry3_path = 'useless/directory/file3'

      entry1 = build_zip_entry_for(entry1_path)
      entry2 = build_zip_entry_for(entry2_path)
      entry3 = build_zip_entry_for(entry3_path)

      stub_make_directory
      stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path, options)

      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/containing1'))
      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/containing2'))

      extractor.extract
    end

    it 'extracts the entry into the stripped extract path when a strip path option is supplied' do
      zip_file_path = 'some/path/to/the-file.zip'
      extract_path = 'some/path/for/extraction'
      options = {strip_path: 'useless/directory'}

      entry1_path = 'useless/directory/containing1/file1'
      entry2_path = 'useless/directory/containing2/file2'
      entry3_path = 'useless/directory/file3'

      entry1 = build_zip_entry_for(entry1_path)
      entry2 = build_zip_entry_for(entry2_path)
      entry3 = build_zip_entry_for(entry3_path)

      stub_make_directory
      zip_file = stub_zip_file_open_for(entry1, entry2, entry3)

      extractor = ZipExtractor.new(zip_file_path, extract_path, options)

      expect(zip_file).to(receive(:extract).with(entry1, File.join(extract_path, 'containing1/file1')))
      expect(zip_file).to(receive(:extract).with(entry2, File.join(extract_path, 'containing2/file2')))
      expect(zip_file).to(receive(:extract).with(entry3, File.join(extract_path, 'file3')))

      extractor.extract
    end

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
              rename_to: 'some/path/the-binary'})

      expect(FileUtils).to(receive(:mkdir_p).with('some/path'))
      expect(FileUtils)
          .to(receive(:mv)
                  .with(
                      File.join(extract_path, 'directory/containing1/file1'),
                      'some/path/the-binary'))

      extractor.extract
    end
  end

  context RakeDependencies::Extractors::TarGzExtractor do
    def stub_gzip_file_open
      tar_file = double('tar file')
      allow(Zlib::GzipReader).to(receive(:open).and_yield(tar_file))
      tar_file
    end

    def build_tar_entry_for(entry_path, options = {file: true, mode: 644, contents: 'Content'})
      entry = double(entry_path)
      allow(entry).to(receive(:name).and_return(entry_path))
      allow(entry).to(receive(:file?).and_return(options[:file]))
      allow(entry).to(receive(:mode).and_return(options[:mode]))
      allow(entry).to(receive(:read).and_return(options[:contents]))
      entry
    end

    def stub_tar_file_open
      stub_tar_file_open_for
    end

    def stub_tar_file_open_for(*entries)
      tar_file_entries = double('tar file entries')

      receive_entries = entries.reduce(receive(:each)) do |receiver, entry|
        receiver.and_yield(entry)
      end

      allow(tar_file_entries).to(receive_entries)
      allow(Archive::Tar::Minitar).to(receive(:open).and_yield(tar_file_entries))

      tar_file_entries
    end

    def stub_file_open
      allow(File).to(receive(:open))
    end

    it 'recursively makes the extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_gzip_file_open
      stub_tar_file_open

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      expect(FileUtils).to(receive(:mkdir_p).with(extract_path))

      extractor.extract
    end

    it 'decompresses the tgz file at the provided path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_gzip_file_open
      stub_tar_file_open

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      expect(Zlib::GzipReader).to(receive(:open).with(tgz_file_path))

      extractor.extract
    end

    it 'opens the resulting tar file' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      tar_file = stub_gzip_file_open
      stub_tar_file_open
      stub_make_directory

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)

      expect(Archive::Tar::Minitar).to(receive(:open).with(tar_file))

      extractor.extract
    end

    it 'recursively makes directories for the tgz file entries under the extract path' do
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

      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/directory/containing1'))
      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/directory/containing2'))

      extractor.extract
    end

    it 'extracts the entry into the extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      entry1 = build_tar_entry_for('directory', file: false, mode: 755)
      entry2 = build_tar_entry_for('directory/containing1', file: false, mode: 755)
      entry3 = build_tar_entry_for('directory/containing1/file1', file: true, mode: 644, contents: 'File1')
      entry4 = build_tar_entry_for('directory/containing2', file: false, mode: 755)
      entry5 = build_tar_entry_for('directory/containing2/file2', file: true, mode: 644, contents: 'File2')
      entry6 = build_tar_entry_for('file3', file: true, mode: 644, contents: 'File3')

      stub_gzip_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)
      extractor.extract

      expect(File.open('some/path/for/extraction/directory/containing1/file1') {|f| f.read}).to eq('File1')
      expect(File.open('some/path/for/extraction/directory/containing2/file2') {|f| f.read}).to eq('File2')
      expect(File.open('some/path/for/extraction/file3') {|f| f.read}).to eq('File3')
    end

    it 'does not extract the entry if a file already exists at the extract path' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      existing_entry_path = 'directory/containing1/file1'
      existing_entry = build_tar_entry_for(existing_entry_path, file: true, mode: 644, contents: 'File1')

      stub_gzip_file_open
      stub_tar_file_open_for(existing_entry)

      full_entry_path = File.join(extract_path, existing_entry_path)
      FileUtils.mkdir_p(File.dirname(full_entry_path))
      File.open(full_entry_path, 'w') {|f| f.write('Existing')}

      extractor = TarGzExtractor.new(tgz_file_path, extract_path)
      extractor.extract

      expect(File.open(full_entry_path) {|f| f.read}).to eq('Existing')
    end

    it 'recursively makes directories for the stripped tgz file entries when a strip path option is supplied' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'
      options = {strip_path: 'useless/directory'}

      entry1 = build_tar_entry_for('useless/directory/containing1/file1')
      entry2 = build_tar_entry_for('useless/directory/containing2/file2')
      entry3 = build_tar_entry_for('useless/directory/file3')

      stub_gzip_file_open
      stub_make_directory
      stub_file_open
      stub_tar_file_open_for(entry1, entry2, entry3)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path, options)

      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/containing1'))
      expect(FileUtils).to(receive(:mkdir_p).with('some/path/for/extraction/containing2'))

      extractor.extract
    end

    it 'extracts the entry into the stripped extract path when a strip path option is supplied' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'
      options = {strip_path: 'useless/directory'}

      entry1 = build_tar_entry_for('useless/directory', file: false, mode: 755)
      entry2 = build_tar_entry_for('useless/directory/containing1', file: false, mode: 755)
      entry3 = build_tar_entry_for('useless/directory/containing1/file1', file: true, mode: 644, contents: 'File1')
      entry4 = build_tar_entry_for('useless/directory/containing2', file: false, mode: 755)
      entry5 = build_tar_entry_for('useless/directory/containing2/file2', file: true, mode: 644, contents: 'File2')
      entry6 = build_tar_entry_for('useless/directory/file3', file: true, mode: 644, contents: 'File3')

      stub_gzip_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(tgz_file_path, extract_path, options)
      extractor.extract

      expect(File.open('some/path/for/extraction/containing1/file1') {|f| f.read}).to eq('File1')
      expect(File.open('some/path/for/extraction/containing2/file2') {|f| f.read}).to eq('File2')
      expect(File.open('some/path/for/extraction/file3') {|f| f.read}).to eq('File3')
    end

    it 'renames the resulting binary when rename from and to are specified' do
      tgz_file_path = 'some/path/to/the-file.tar.gz'
      extract_path = 'some/path/for/extraction'

      entry1 = build_tar_entry_for('directory', file: false, mode: 755)
      entry2 = build_tar_entry_for('directory/containing1', file: false, mode: 755)
      entry3 = build_tar_entry_for('directory/containing1/file1', file: true, mode: 644, contents: 'File1')
      entry4 = build_tar_entry_for('directory/containing2', file: false, mode: 755)
      entry5 = build_tar_entry_for('directory/containing2/file2', file: true, mode: 644, contents: 'File2')
      entry6 = build_tar_entry_for('file3', file: true, mode: 644, contents: 'File3')

      stub_gzip_file_open
      stub_make_directory
      stub_file_open
      stub_tar_file_open_for(entry1, entry2, entry3, entry4, entry5, entry6)

      extractor = TarGzExtractor.new(
          tgz_file_path, extract_path,
          {
              rename_from: 'directory/containing1/file1',
              rename_to: 'some/path/the-binary'})

      expect(FileUtils).to(receive(:mkdir_p).with('some/path'))
      expect(FileUtils)
          .to(receive(:mv)
                  .with(
                      File.join(extract_path, 'directory/containing1/file1'),
                      'some/path/the-binary'))

      extractor.extract
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

      extractor = UncompressedExtractor.new(uncompressed_file_path, extract_path)

      expect(FileUtils)
          .to(receive(:mkdir_p).with('some/path/for/extraction'))

      extractor.extract
    end

    it 'copies the binary to the target path' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(uncompressed_file_path, extract_path)

      expect(FileUtils)
          .to(receive(:cp)
                  .with(uncompressed_file_path, 'some/path/for/extraction/the-file'))

      extractor.extract
    end

    it 'renames the binary when the rename_from and rename_to options are provided' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'
      options = {rename_to: 'other-file'}

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(uncompressed_file_path, extract_path, options)

      expect(FileUtils)
          .to(receive(:cp)
                  .with(uncompressed_file_path, 'some/path/for/extraction/other-file'))

      extractor.extract
    end

    it 'makes the target file executable' do
      uncompressed_file_path = 'some/path/to/the-file'
      extract_path = 'some/path/for/extraction'

      stub_make_directory
      stub_copy_file
      stub_chmod_file

      extractor = UncompressedExtractor.new(uncompressed_file_path, extract_path)

      expect(FileUtils)
          .to(receive(:chmod)
                  .with(0755, 'some/path/for/extraction/the-file'))

      extractor.extract
    end
  end
end
