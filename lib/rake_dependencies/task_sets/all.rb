require 'rake_factory'

require_relative '../tasks/clean'
require_relative '../tasks/download'
require_relative '../tasks/ensure'
require_relative '../tasks/extract'
require_relative '../tasks/fetch'


module RakeDependencies
  module TaskSets
    class All < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :containing_namespace

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true
      parameter :type, default: :zip

      parameter :os_ids, default: {mac: 'mac', linux: 'linux'}

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'
      parameter :installation_directory

      parameter :uri_template, required: true
      parameter :file_name_template, required: true
      parameter :strip_path_template

      parameter :source_binary_name_template
      parameter :target_binary_name_template

      parameter :needs_fetch, required: true, lazy: true

      parameter :clean_task_name, default: :clean
      parameter :download_task_name, default: :download
      parameter :extract_task_name, default: :extract
      parameter :install_task_name, default: :install
      parameter :fetch_task_name, default: :fetch
      parameter :ensure_task_name, default: :ensure

      task Tasks::Clean, name: ->(ts) { ts.clean_task_name }
      task Tasks::Download, name: ->(ts) { ts.download_task_name }
      task Tasks::Extract, name: ->(ts) { ts.extract_task_name }
      task Tasks::Install, {
          name: ->(ts) { ts.install_task_name },
          define_if: ->(ts) { ts.installation_directory }
      } do |ts, t|
        t.binary_name_template =
            ts.target_binary_name_template || ts.dependency
      end
      task Tasks::Fetch, name: ->(ts) { ts.fetch_task_name }
      task Tasks::Ensure, name: ->(ts) { ts.ensure_task_name }
    end
  end
end
