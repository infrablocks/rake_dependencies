require 'rake_factory'

module RakeDependencies
  module Tasks
    class Install < RakeFactory::Task
      default_name :install
      default_description ->(t) { "Install #{t.dependency}" }

      parameter :os_ids, default: {
          mac: 'mac',
          linux: 'linux'
      }

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
            os_id: os_id,
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
