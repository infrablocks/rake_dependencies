require_relative '../tasklib'

module RakeDependencies
  module Tasks
    class Clean < TaskLib
      parameter :name, :default => :clean
      parameter :path, :required => true
      parameter :dependency, :required => true

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Clean vendored #{dependency}"
        task name do
          rm_rf path
        end
      end
    end
  end
end