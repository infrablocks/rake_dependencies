require 'rake_factory'

module RakeDependencies
  module Tasks
    class Ensure < RakeFactory::Task
      default_name :ensure
      default_description RakeFactory::DynamicValue.new { |t|
        "Ensure #{t.dependency} present"
      }

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true

      parameter :binary_directory, default: 'bin'

      parameter :needs_fetch, default: true

      parameter :clean_task_name, default: :clean
      parameter :download_task_name, default: :download
      parameter :extract_task_name, default: :extract
      parameter :install_task_name, default: :install

      action do |t|
        clean = Rake::Task[t.scope.path_with_task_name(t.clean_task_name)]
        download = Rake::Task[t.scope.path_with_task_name(t.download_task_name)]
        extract = Rake::Task[t.scope.path_with_task_name(t.extract_task_name)]

        install_name = t.scope.path_with_task_name(t.install_task_name)
        install = if Rake::Task.task_defined?(install_name)
          Rake::Task[install_name]
        end

        if needs_fetch.call(t)
          [clean, download, extract, install].compact.map(&:invoke)
        end
      end
    end
  end
end
