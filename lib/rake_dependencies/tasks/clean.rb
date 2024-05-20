# frozen_string_literal: true

require 'rake_factory'
require 'logger'

require_relative '../null_logger'

module RakeDependencies
  module Tasks
    class Clean < RakeFactory::Task
      default_name :clean
      default_description(RakeFactory::DynamicValue.new do |t|
        "Clean vendored #{t.dependency}"
      end)

      parameter :dependency, required: true
      parameter :path, required: true

      parameter :logger, default: NullLogger.new

      action do |t|
        logger.info("Cleaning '#{dependency}' at path: '#{path}'...")
        rm_rf t.path
        logger.info('Cleaned.')
      end
    end
  end
end
