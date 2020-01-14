require 'rake_factory'

require_relative 'clean'
require_relative 'download'
require_relative 'ensure'
require_relative 'extract'
require_relative 'fetch'


module RakeDependencies
  module Tasks
    class All < RakeFactory::TaskSet
      parameter :containing_namespace

      parameter :dependency, :required => true
      parameter :version
      parameter :path, :required => true
      parameter :type, :default => :zip

      parameter :os_ids, default: {mac: 'mac', linux: 'linux'}

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'
      parameter :installation_directory

      parameter :uri_template, :required => true
      parameter :file_name_template, :required => true
      parameter :strip_path_template

      parameter :source_binary_name_template
      parameter :target_binary_name_template

      parameter :needs_fetch, :required => true

      parameter :clean_task_name, :default => :clean
      parameter :download_task_name, :default => :download
      parameter :extract_task_name, :default => :extract
      parameter :install_task_name, :default => :install
      parameter :fetch_task_name, :default => :fetch
      parameter :ensure_task_name, :default => :ensure

      alias namespace= containing_namespace=

      task Clean, name: ->(ts) { ts.clean_task_name }
      task Download, name: ->(ts) { ts.download_task_name }
      task Extract, name: ->(ts) { ts.extract_task_name }
      task Install, {
          name: ->(ts) { ts.install_task_name },
          define_if: ->(ts) { ts.installation_directory }
      } do |ts, t|
        t.binary_name_template =
            ts.target_binary_name_template || ts.dependency
      end
      task Fetch, name: ->(ts) { ts.fetch_task_name }
      task Ensure, name: ->(ts) { ts.ensure_task_name }

      def define_on(application)
        if containing_namespace
          namespace containing_namespace do
            super(application)
          end
        else
          super(application)
        end
      end
    end
  end
end
