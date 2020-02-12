require 'rake_factory'

module RakeDependencies
  module Tasks
    class Fetch < RakeFactory::Task
      default_name :fetch
      default_description RakeFactory::DynamicValue.new { |t|
        "Fetch #{t.dependency}"
      }

      parameter :dependency, required: true
      parameter :download_task_name, default: :download
      parameter :extract_task_name, default: :extract

      action do |t|
        [
            Rake::Task[t.scope.path_with_task_name(t.download_task_name)],
            Rake::Task[t.scope.path_with_task_name(t.extract_task_name)]
        ].each do |task|
          task.invoke
        end
      end
    end
  end
end
