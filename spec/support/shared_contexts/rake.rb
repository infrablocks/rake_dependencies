# frozen_string_literal: true

require 'rake'

# needed to prevent fakefs errors
require 'pp' # rubocop:disable Lint/RedundantRequireStatement

require 'fakefs/spec_helpers'

# rubocop:disable RSpec/ContextWording
shared_context 'rake' do
  include Rake::DSL if defined?(Rake::DSL)
  include FakeFS::SpecHelpers

  subject { self.class.top_level_description.constantize }

  let(:rake) { Rake::Application.new }

  before do
    Rake.application = rake
  end

  before do
    Rake::Task.clear
  end
end
# rubocop:enable RSpec/ContextWording
