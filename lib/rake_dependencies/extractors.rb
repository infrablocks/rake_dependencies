require 'zip'
require 'zlib'
require 'pathname'
require 'archive/tar/minitar'

module RakeDependencies
  module Extractors
    class ZipExtractor
      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        FileUtils.mkdir_p(@extract_path)
        Zip::File.open(@file_path) do |zip_file_entries|
          zip_file_entries.each do |entry|
            entry_pathname = Pathname.new(entry.name)
            strip_pathname = Pathname.new(@options[:strip_path] || '')
            target_pathname = entry_pathname.relative_path_from(strip_pathname)

            file_path = File.join(@extract_path, target_pathname)
            FileUtils.mkdir_p(File.dirname(file_path))
            zip_file_entries.extract(entry, file_path) unless File.exist?(file_path)
          end
        end
      end
    end

    class TarGzExtractor
      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        FileUtils.mkdir_p(@extract_path)
        Zlib::GzipReader.open(@file_path) do |tar_file|
          Archive::Tar::Minitar.open(tar_file) do |tar_file_entries|
            tar_file_entries.each do |entry|
              entry_pathname = Pathname.new(entry.name)
              strip_pathname = Pathname.new(@options[:strip_path] || '')
              target_pathname = entry_pathname.relative_path_from(strip_pathname)

              file_path = File.join(@extract_path, target_pathname)
              FileUtils.mkdir_p(File.dirname(file_path))
              if entry.file? && !File.exist?(file_path)
                File.open(file_path, 'w', entry.mode) { |f| f.write(entry.read) }
              end
            end
          end
        end
      end
    end

    class UncompressedExtractor
      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        target_name = @options[:rename_to] || File.basename(@file_path)
        source = @file_path
        destination = File.join(@extract_path, target_name)

        FileUtils.mkdir_p(@extract_path)
        FileUtils.cp(source, destination)
        FileUtils.chmod(0755, destination)
      end
    end
  end
end
