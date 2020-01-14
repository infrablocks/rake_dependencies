require 'rake_factory'

module RakeDependencies
  module Tasks
    class Clean < RakeFactory::Task
      default_name :clean
      default_description ->(t) { "Clean vendored #{t.dependency}" }

      parameter :dependency, :required => true
      parameter :path, :required => true

      action do |t|
        rm_rf t.path
      end
    end
  end
end