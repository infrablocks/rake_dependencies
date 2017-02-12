require_relative '../tasklib'

module RakeDependencies
  module Tasks
    class Fetch < TaskLib
      parameter :name, default: :fetch
      parameter :dependency, required: true
      parameter :download_task, default: :download
      parameter :extract_task, default: :extract

      def process_arguments args
        super(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Fetch #{dependency}"
        task name => [
            scoped_task_name(download_task),
            scoped_task_name(extract_task)
        ]
      end

      private

      def scoped_task_name(task_name)
        Rake.application.current_scope.path_with_task_name(task_name)
      end
    end
  end
end
