require 'open-uri'
require_relative '../tasklib'
require_relative '../template'

module RakeDependencies
  module Tasks
    class Download < TaskLib
      extend FileUtils

      parameter :name, default: :download
      parameter :type, default: :zip
      parameter :os_ids, default: {mac: 'mac', linux: 'linux'}
      parameter :directory, default: 'dist'
      parameter :version
      parameter :path, required: true
      parameter :dependency, required: true
      parameter :uri_template, required: true
      parameter :file_name_template, required: true

      def process_arguments(args)
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Download #{dependency} distribution"
        task name do
          parameters = {
              version: version,
              platform: platform,
              os_id: os_id,
              ext: ext
          }

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

      def os_id
        os_ids[platform]
      end

      def platform
        RUBY_PLATFORM =~ /darwin/ ? :mac : :linux
      end

      def ext
        resolved_type = type.is_a?(Hash) ? type[platform].to_sym : type.to_sym
        case resolved_type
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