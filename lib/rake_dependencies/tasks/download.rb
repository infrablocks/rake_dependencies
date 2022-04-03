# frozen_string_literal: true

require 'down'
require 'rake_factory'
require 'rubygems'

require_relative '../template'
require_relative '../platform_names'

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

      action do
        parameters = {
          version: version,
          platform: platform,
          platform_cpu_name: platform_cpu_name,
          platform_os_name: platform_os_name,
          ext: ext
        }

        uri = Template.new(uri_template)
                      .with_parameters(parameters)
                      .render
        download_file_name = Template.new(file_name_template)
                                     .with_parameters(parameters)
                                     .render
        download_file_directory = File.join(path, distribution_directory)
        download_file_path = File.join(download_file_directory,
                                       download_file_name)

        temporary_file = Down.download(uri)

        mkdir_p download_file_directory
        cp temporary_file.path, download_file_path
      end

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
