# frozen_string_literal: true

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

      parameter :platform_cpu_names, default: PlatformNames::CPU
      parameter :platform_os_names, default: PlatformNames::OS

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'
      parameter :installation_directory

      parameter :uri_template, required: true
      parameter :file_name_template, required: true
      parameter :strip_path_template

      parameter :source_binary_name_template
      parameter :target_binary_name_template

      parameter :needs_fetch, required: true

      parameter :clean_task_name, default: :clean
      parameter :download_task_name, default: :download
      parameter :extract_task_name, default: :extract
      parameter :install_task_name, default: :install
      parameter :fetch_task_name, default: :fetch
      parameter :ensure_task_name, default: :ensure

      task(
        Tasks::Clean, {
          name: (RakeFactory::DynamicValue.new { |ts| ts.clean_task_name })
        }
      )
      task(
        Tasks::Download, {
          name: (RakeFactory::DynamicValue.new { |ts| ts.download_task_name })
        }
      )
      task(
        Tasks::Extract, {
          name: (RakeFactory::DynamicValue.new { |ts| ts.extract_task_name })
        }
      )
      task(
        Tasks::Fetch, {
          name: (RakeFactory::DynamicValue.new { |ts| ts.fetch_task_name })
        }
      )
      task(
        Tasks::Ensure, {
          name: (RakeFactory::DynamicValue.new { |ts| ts.ensure_task_name })
        }
      )
      task(
        Tasks::Install, {
          name:
            (RakeFactory::DynamicValue.new { |ts| ts.install_task_name }),
          binary_name_template:
            (RakeFactory::DynamicValue.new do |ts|
              ts.target_binary_name_template || ts.dependency
            end),
          define_if: ->(ts) { ts.installation_directory }
        }
      )
    end
  end
end
