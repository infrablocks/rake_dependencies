# frozen_string_literal: true

require 'zip'
require 'zlib'
require 'pathname'
require 'minitar'

module RakeDependencies
  module Extractors
    class ZipExtractor
      attr_reader :file_path, :extract_path, :options

      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        create_extract_directory
        extract_files

        return unless requires_rename?

        rename(
          relative_to_extract_directory(rename_from),
          relative_to_extract_directory(rename_to)
        )
      end

      private

      def extract_files
        Zip::File.open(
          file_path, create: false, restore_permissions: true
        ) do |zip_file_entries|
          zip_file_entries.each do |entry|
            process_zip_file_entry(zip_file_entries, entry)
          end
        end
      end

      def process_zip_file_entry(zip_file_entries, entry)
        target_path = relative_to_extract_directory(target_pathname(entry))
        create_base_directory(target_path)
        extract_file_if_needed(zip_file_entries, entry, target_path)
      end

      def extract_file_if_needed(zip_file_entries, entry, target_path)
        return if File.exist?(target_path)

        zip_file_entries.extract(entry, target_path)
      end

      def requires_rename?
        rename_from && rename_to
      end

      def relative_to_extract_directory(path)
        File.join(extract_path, path)
      end

      def create_base_directory(path)
        FileUtils.mkdir_p(File.dirname(path))
      end

      def create_extract_directory
        FileUtils.mkdir_p(extract_path)
      end

      def move(from, to)
        FileUtils.mv(from, to)
      end

      def rename(from, to)
        create_base_directory(to)
        move(from, to)
      end

      def target_pathname(entry)
        entry_pathname(entry).relative_path_from(strip_pathname)
      end

      def strip_pathname
        Pathname.new(strip_path)
      end

      def entry_pathname(entry)
        Pathname.new(entry.name)
      end

      def rename_to
        options[:rename_to]
      end

      def rename_from
        options[:rename_from]
      end

      def strip_path
        options[:strip_path] || ''
      end
    end

    class TarGzExtractor
      attr_reader :file_path, :extract_path, :options

      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        create_extract_directory
        extract_files

        return unless requires_rename?

        rename(
          relative_to_extract_directory(rename_from),
          relative_to_extract_directory(rename_to)
        )
      end

      private

      def extract_files
        Zlib::GzipReader.open(file_path) do |tar_file|
          Minitar.open(tar_file) do |tar_file_entries|
            tar_file_entries.each(&method(:process_tar_file_entry))
          end
        end
      end

      def process_tar_file_entry(entry)
        target_path = relative_to_extract_directory(target_pathname(entry))
        create_base_directory(target_path)
        extract_file_if_needed(entry, target_path)
      end

      def extract_file_if_needed(entry, target_path)
        return unless entry.file? && !File.exist?(target_path)

        File.open(target_path, 'w', entry.mode) do |f|
          f.write(entry.read)
        end
      end

      def requires_rename?
        rename_from && rename_to
      end

      def relative_to_extract_directory(path)
        File.join(extract_path, path)
      end

      def create_base_directory(path)
        FileUtils.mkdir_p(File.dirname(path))
      end

      def create_extract_directory
        FileUtils.mkdir_p(extract_path)
      end

      def move(from, to)
        FileUtils.mv(from, to)
      end

      def rename(from, to)
        create_base_directory(to)
        move(from, to)
      end

      def target_pathname(entry)
        entry_pathname(entry).relative_path_from(strip_pathname)
      end

      def strip_pathname
        Pathname.new(strip_path)
      end

      def entry_pathname(entry)
        Pathname.new(entry.name)
      end

      def rename_to
        options[:rename_to]
      end

      def rename_from
        options[:rename_from]
      end

      def strip_path
        options[:strip_path] || ''
      end
    end

    class UncompressedExtractor
      attr_reader :file_path, :extract_path, :options

      def initialize(file_path, extract_path, options = {})
        @file_path = file_path
        @extract_path = extract_path
        @options = options
      end

      def extract
        target_name = rename_to || file_name
        source_path = file_path
        target_path = relative_to_extract_directory(target_name)

        create_extract_directory
        move(source_path, target_path)
        fix_permissions(target_path)
      end

      private

      def file_name
        File.basename(file_path)
      end

      def fix_permissions(target_path)
        FileUtils.chmod(0o755, target_path)
      end

      def move(source_path, target_path)
        FileUtils.cp(source_path, target_path)
      end

      def relative_to_extract_directory(path)
        File.join(extract_path, path)
      end

      def create_extract_directory
        FileUtils.mkdir_p(extract_path)
      end

      def rename_to
        options[:rename_to]
      end
    end
  end
end
