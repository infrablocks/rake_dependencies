require 'rake_factory'
require 'rubygems'

require_relative '../template'

module RakeDependencies
  module Tasks
    class Install < RakeFactory::Task
      default_name :install
      default_description RakeFactory::DynamicValue.new { |t|
        "Install #{t.dependency}"
      }

      parameter :platform_cpu_names, default: PlatformNames::CPU
      parameter :platform_os_names, default: PlatformNames::OS

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true
      parameter :type, default: :zip

      parameter :binary_directory, default: 'bin'
      parameter :binary_name_template, required: true

      parameter :installation_directory, required: true

      action do
        parameters = {
            version: version,
            platform: platform,
            platform_cpu_name: platform_cpu_name,
            platform_os_name: platform_os_name,
            ext: ext
        }

        binary_file_name = Template.new(binary_name_template)
            .with_parameters(parameters)
            .render
        binary_file_directory = File.join(path, binary_directory)
        binary_file_path = File.join(
            binary_file_directory, binary_file_name)

        mkdir_p installation_directory
        cp binary_file_path, installation_directory
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
        when :tar_gz then
          '.tar.gz'
        when :tgz then
          '.tgz'
        when :zip then
          '.zip'
        when :uncompressed then
          ''
        else
          raise "Unknown type: #{type}"
        end
      end
    end
  end
end
