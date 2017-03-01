require_relative 'clean'
require_relative 'download'
require_relative 'ensure'
require_relative 'extract'
require_relative 'fetch'
require_relative '../tasklib'

module RakeDependencies
  module Tasks
    class All < TaskLib
      parameter :containing_namespace

      parameter :dependency, :required => true
      parameter :version, :required => true
      parameter :path, :required => true
      parameter :type, :default => :zip

      parameter :os_ids, default: {mac: 'mac', linux: 'linux'}

      parameter :distribution_directory, default: 'dist'
      parameter :binary_directory, default: 'bin'

      parameter :uri_template, :required => true
      parameter :file_name_template, :required => true
      parameter :target_name_template
      parameter :strip_path_template

      parameter :needs_fetch, :required => true

      parameter :clean_task_name, :default => :clean
      parameter :download_task_name, :default => :download
      parameter :extract_task_name, :default => :extract
      parameter :fetch_task_name, :default => :fetch
      parameter :ensure_task_name, :default => :ensure

      alias namespace= containing_namespace=

      def define
        namespace containing_namespace do
          Clean.new do |t|
            t.name = clean_task_name

            t.dependency = dependency
            t.path = path
          end
          Download.new do |t|
            t.name = download_task_name

            t.dependency = dependency
            t.version = version
            t.path = path
            t.type = type

            t.os_ids = os_ids

            t.distribution_directory = distribution_directory

            t.uri_template = uri_template
            t.file_name_template = file_name_template
          end
          Extract.new do |t|
            t.name = extract_task_name

            t.dependency = dependency
            t.version = version
            t.path = path
            t.type = type

            t.os_ids = os_ids

            t.distribution_directory = distribution_directory
            t.binary_directory = binary_directory

            t.file_name_template = file_name_template
            t.strip_path_template = strip_path_template
            t.target_name_template = target_name_template
          end
          Fetch.new do |t|
            t.name = fetch_task_name

            t.dependency = dependency

            t.download_task = download_task_name
            t.extract_task = extract_task_name
          end
          Ensure.new do |t|
            t.name = ensure_task_name

            t.dependency = dependency
            t.version = version
            t.path = path

            t.binary_directory = binary_directory

            t.needs_fetch = needs_fetch

            t.clean_task = clean_task_name
            t.download_task = download_task_name
            t.extract_task = extract_task_name
          end
        end
      end
    end
  end
end