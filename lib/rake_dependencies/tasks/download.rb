# frozen_string_literal: true

require 'down'
require 'rake_factory'
require 'rubygems'

require_relative '../template'
require_relative '../platform_names'
require_relative '../null_logger'

module RakeDependencies
  module Tasks
    class Download < RakeFactory::Task
      default_name :download
      default_description(RakeFactory::DynamicValue.new do |t|
        "Download #{t.dependency} distribution"
      end)

      parameter :type, default: :zip

      parameter :platform_cpu_names, default: PlatformNames::CPU
      parameter :platform_os_names, default: PlatformNames::OS

      parameter :distribution_directory, default: 'dist'

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true
      parameter :uri_template, required: true
      parameter :file_name_template, required: true

      parameter :logger, default: NullLogger.new

      # rubocop:disable Metrics/BlockLength
      action do
        logger.info("Downloading '#{dependency}' (version #{version})...")

        parameters = {
          version:,
          platform:,
          platform_cpu_name:,
          platform_os_name:,
          ext:
        }

        logger.debug(
          "Using parameters: #{parameters.merge({ platform: platform.to_s })}."
        )

        uri = Template.new(uri_template)
                      .with_parameters(parameters)
                      .render

        logger.debug("Using URI: #{uri}.")

        download_file_name = Template.new(file_name_template)
                                     .with_parameters(parameters)
                                     .render
        download_file_directory = File.join(path, distribution_directory)
        download_file_path = File.join(download_file_directory,
                                       download_file_name)

        logger.debug("Using distribution file path: #{download_file_path}.")

        temporary_file = Down.download(uri)

        mkdir_p download_file_directory
        cp temporary_file.path, download_file_path

        logger.info('Downloaded.')
      end
      # rubocop:enable Metrics/BlockLength

      private

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
  end
end
