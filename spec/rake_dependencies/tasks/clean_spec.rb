require 'spec_helper'
require 'fileutils'

describe RakeDependencies::Tasks::Clean do
  include_context :rake

  it 'adds a clean task in the namespace in which it is created' do
    namespace :dependency do
      subject.define(dependency: 'something') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:clean']).not_to be_nil
  end

  it 'gives the clean task a description' do
    namespace :dependency do
      subject.define(dependency: 'the-thing') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:clean'].full_comment)
        .to(eq('Clean vendored the-thing'))
  end

  it 'allows the task name to be overridden' do
    namespace :dependency do
      subject.define(name: :remove, dependency: 'something') do |t|
        t.path = 'some/path'
      end
    end

    expect(Rake::Task['dependency:remove']).not_to be_nil
  end

  it 'allows multiple clean tasks to be declared' do
    namespace :dependency1 do
      subject.define(dependency: 'something1') do |t|
        t.path = 'some/path/for/1'
      end
    end

    namespace :dependency2 do
      subject.define(dependency: 'something2') do |t|
        t.path = 'some/path/for/2'
      end
    end

    dependency1_clean = Rake::Task['dependency1:clean']
    dependency2_clean = Rake::Task['dependency2:clean']

    expect(dependency1_clean).not_to be_nil
    expect(dependency2_clean).not_to be_nil
  end

  it 'recursively removes the dependency download path' do
    path = 'vendor/dependency'

    subject.define(dependency: 'something') do |t|
      t.path = path
    end

    expect_any_instance_of(subject).to(receive(:rm_rf).with(path))

    Rake::Task['clean'].invoke
  end

  it 'fails if no path is provided' do
    subject.define(dependency: 'something')

    expect {
      Rake::Task['clean'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end
end
