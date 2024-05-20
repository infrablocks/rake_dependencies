# frozen_string_literal: true

require 'rake_factory'
require 'zip'
require 'rubygems'

require_relative '../template'
require_relative '../extractors'
require_relative '../null_logger'

module RakeDependencies
  module Tasks
    # rubocop:disable Metrics/ClassLength
    class Extract < RakeFactory::Task
      default_name :extract
      default_description(RakeFactory::DynamicValue.new do |t|
        "Extract #{t.dependency} archive"
      end)

      parameter :type, default: :zip

      parameter :platform_cpu_names, default: PlatformNames::CPU
      parameter :platform_os_names, default: PlatformNames::OS

      parameter :extractors, default: {
        zip: Extractors::ZipExtractor,
        tar_gz: Extractors::TarGzExtractor,
        tgz: Extractors::TarGzExtractor,
        uncompressed: Extractors::UncompressedExtractor
      }

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true
      parameter :file_name_template, required: true
      parameter :source_binary_name_template
      parameter :target_binary_name_template
      parameter :strip_path_template

      parameter :logger, default: NullLogger.new

      # rubocop:disable Metrics/BlockLength
      action do
        logger.info("Extracting '#{dependency}'...")

        logger.debug(
          "Using parameters: #{parameters.merge(platform: platform.to_s)}."
        )

        distribution_file_name = interpolate_file_name_template(parameters)
        distribution_file_directory = relative_to_path(distribution_directory)
        distribution_file_path = File.join(
          distribution_file_directory, distribution_file_name
        )

        logger.debug("Using distribution file path: #{distribution_file_path}.")

        extraction_path = relative_to_path(binary_directory)

        logger.debug("Using extraction path: #{extraction_path}.")

        options = {}
        if strip_path_template
          options[:strip_path] = interpolate_strip_path_template(parameters)
        end

        if source_binary_name_template && target_binary_name_template
          options[:rename_from] =
            interpolate_source_binary_name_template(parameters)
          options[:rename_to] =
            interpolate_target_binary_name_template(parameters)
        end

        logger.debug("Using extraction options: #{options}.")

        extractor = extractor_for_extension.new(
          distribution_file_path,
          extraction_path,
          options
        )
        extractor.extract

        logger.info('Extracted.')
      end
      # rubocop:enable Metrics/BlockLength

      def parameters
        {
          version: version,
          platform: platform,
          platform_cpu_name: platform_cpu_name,
          platform_os_name: platform_os_name,
          ext: ext
        }
      end

      def interpolate_template(template, parameters)
        Template.new(template)
                .with_parameters(parameters)
                .render
      end

      def interpolate_file_name_template(parameters)
        interpolate_template(file_name_template, parameters)
      end

      def interpolate_strip_path_template(parameters)
        interpolate_template(strip_path_template, parameters)
      end

      def interpolate_source_binary_name_template(parameters)
        interpolate_template(source_binary_name_template, parameters)
      end

      def interpolate_target_binary_name_template(parameters)
        interpolate_template(target_binary_name_template, parameters)
      end

      def relative_to_path(other)
        File.join(path, other)
      end

      def extractor_for_extension
        extractors[resolved_type]
      end

      def platform
        Gem::Platform.local
      end

      def platform_os_name
        platform_os_names[platform.os.to_sym]
      end

      def platform_cpu_name
        platform_cpu_names[platform.cpu.to_sym]
      end

      def resolved_type
        type.is_a?(Hash) ? type[platform.os.to_sym].to_sym : type.to_sym
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
    # rubocop:enable Metrics/ClassLength
  end
end
