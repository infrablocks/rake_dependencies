require 'mattock'

module RakeDependencies
  module Tasks
    class Clean < Mattock::Tasklib
      setting :name, :clean
      required_fields :path
      required_fields :dependency

      def default_configuration(*args)
        super(args)
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