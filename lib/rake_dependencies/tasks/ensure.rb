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
      parameter :install_task, default: :install

      def process_arguments args
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        clean = Rake::Task[scoped_task_name(clean_task)]
        download = Rake::Task[scoped_task_name(download_task)]
        extract = Rake::Task[scoped_task_name(extract_task)]

        resolved_install_task = scoped_task_name(install_task)
        install = if Rake::Task.task_defined?(resolved_install_task)
                    Rake::Task[scoped_task_name(install_task)]
                  else
                    no_op_task = Object.new
                    def no_op_task.invoke; end
                    no_op_task
                  end

        desc "Ensure #{dependency} present"
        task name do
          parameters = {
              path: path,
              version: version,
              binary_directory: binary_directory
          }
          if needs_fetch.call(parameters)
            [clean, download, extract, install].map(&:invoke)
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
