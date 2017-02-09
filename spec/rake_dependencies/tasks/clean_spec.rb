require 'spec_helper'
require 'fileutils'

describe RakeDependencies::Tasks::Clean do
  include_context :rake

  it 'adds a clean task in the namespace in which it is created' do
    namespace :dependency do
      subject.new do |t|
        t.path = 'some/path'
        t.dependency = 'something'
      end
    end

    expect(Rake::Task['dependency:clean']).not_to be_nil
  end

  it 'gives the clean task a description' do
    namespace :dependency do
      subject.new do |t|
        t.path = 'some/path'
        t.dependency = 'the-thing'
      end
    end

    expect(rake.last_description).to(eq('Clean vendored the-thing'))
  end

  it 'allows the task name to be overridden' do
    namespace :dependency do
      subject.new(:remove) do |t|
        t.path = 'some/path'
        t.dependency = 'something'
      end
    end

    expect(Rake::Task['dependency:remove']).not_to be_nil
  end

  it 'recursively removes the dependency download path' do
    path = 'vendor/dependency'

    subject.new do |t|
      t.path = path
      t.dependency = 'something'
    end

    expect_any_instance_of(subject).to(receive(:rm_rf).with(path))

    Rake::Task['clean'].invoke
  end

  it 'fails if no path is provided' do
    expect {
      subject.new do |t|
        t.dependency = 'something'
      end
    }.to raise_error(Calibrate::RequiredFieldUnset)
  end
end
