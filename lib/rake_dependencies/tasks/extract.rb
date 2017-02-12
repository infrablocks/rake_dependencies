require 'zip'
require_relative '../tasklib'
require_relative '../template'
require_relative '../extractors'

module RakeDependencies
  module Tasks
    class Extract < TaskLib
      parameter :name, default: :extract

      parameter :type, default: :zip
      parameter :os_ids, default: {
          mac: 'mac',
          linux: 'linux'
      }
      parameter :extractors, default: {
          zip: Extractors::ZipExtractor,
          tar_gz: Extractors::TarGzExtractor,
          tgz: Extractors::TarGzExtractor
      }

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true
      parameter :file_name_template, required: true
      parameter :strip_path_template

      def process_arguments args
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Extract #{dependency} archive"
        task name do
          parameters = {
              version: version,
              platform: platform,
              os_id: os_id,
              ext: ext
          }

          distribution_file_name = Template.new(file_name_template)
             .with_parameters(parameters)
             .render
          distribution_file_directory = File.join(path, distribution_directory)
          distribution_file_path = File.join(
              distribution_file_directory, distribution_file_name)

          extraction_path = File.join(path, binary_directory)

          options = {}
          if strip_path_template
            options[:strip_path] = Template.new(strip_path_template)
               .with_parameters(parameters)
               .render
          end

          extractor = extractor_for_extension.new(
              distribution_file_path,
              extraction_path,
              options)
          extractor.extract
        end
      end

      private

      def extractor_for_extension
        extractors[resolved_type]
      end

      def os_id
        os_ids[platform]
      end

      def platform
        RUBY_PLATFORM =~ /darwin/ ? :mac : :linux
      end

      def resolved_type
        type.is_a?(Hash) ? type[platform].to_sym : type.to_sym
      end

      def ext
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