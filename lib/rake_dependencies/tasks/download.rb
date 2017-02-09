require 'mattock'
require 'open-uri'
require_relative '../template'

module RakeDependencies
  module Tasks
    class Download < Mattock::Tasklib
      extend FileUtils

      setting :name, :download
      setting :type, :zip
      setting :directory, 'dist'
      required_fields :path
      required_fields :dependency
      required_fields :version
      required_fields :uri_template
      required_fields :file_name_template

      def default_configuration(*args)
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Download #{dependency} distribution"
        task name do
          parameters = {version: version, os: os, ext: ext}

          uri = Template.new(uri_template)
            .with_parameters(parameters)
            .render
          download_file_name = Template.new(file_name_template)
            .with_parameters(parameters)
            .render
          download_file_directory = File.join(path, directory)
          download_file_path = File.join(download_file_directory, download_file_name)

          temporary_file = open(uri)

          mkdir_p download_file_directory
          cp temporary_file.path, download_file_path
        end
      end

      private

      def os
        RUBY_PLATFORM =~ /darwin/ ? :mac : :linux
      end

      def ext
        case type.to_sym
          when :tar_gz then '.tar.gz'
          when :tgz then '.tgz'
          when :zip then '.zip'
          when :uncompressed then ''
          else
            raise "Unknown type: #{type}"
        end
      end
    end
  end
end