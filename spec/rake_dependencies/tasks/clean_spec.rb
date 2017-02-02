require 'spec_helper'
require 'fileutils'

describe RakeDependencies::Tasks::Clean do
  include_context :rake

  it 'adds a clean task in the namespace in which it is created' do
    namespace :dependency do
      subject.new do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:clean']).not_to be_nil
  end

  it 'allows the task name to be overridden' do
    namespace :dependency do
      subject.new(:remove) do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:remove']).not_to be_nil
  end

  it 'recursively removes the dependency download path' do
    path = 'vendor/dependency'

    subject.new do |t|
      t.path = path
    end

    expect_any_instance_of(FileUtils).to(receive(:rm_rf).with(path, any_args))

    Rake::Task['clean'].invoke
  end

  it 'fails if no path is provided' do
    expect {
      subject.new do |t|
      end
    }.to raise_error(Calibrate::RequiredFieldUnset)
  end
end
