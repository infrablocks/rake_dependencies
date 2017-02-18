require_relative '../tasklib'

module RakeDependencies
  module Tasks
    class Ensure < TaskLib
      parameter :name, default: :ensure

      parameter :dependency, required: true
      parameter :version
      parameter :path, required: true

      parameter :binary_directory, default: 'bin'

      parameter :needs_fetch, default: lambda { |_| true }

      parameter :clean_task, default: :clean
      parameter :download_task, default: :download
      parameter :extract_task, default: :extract

      def process_arguments args
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        clean = Rake::Task[scoped_task_name(clean_task)]
        download = Rake::Task[scoped_task_name(download_task)]
        extract = Rake::Task[scoped_task_name(extract_task)]

        desc "Ensure #{dependency} present"
        task name do
          parameters = {
              path: path,
              version: version,
              binary_directory: binary_directory
          }
          if needs_fetch.call(parameters)
            [clean, download, extract].map(&:invoke)
          end
        end
      end

      private

      def scoped_task_name(task_name)
        Rake.application.current_scope.path_with_task_name(task_name)
      end
    end
  end
end