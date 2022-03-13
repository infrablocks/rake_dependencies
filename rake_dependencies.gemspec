# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_dependencies/version'

Gem::Specification.new do |spec|
  spec.name = 'rake_dependencies'
  spec.version = RakeDependencies::VERSION
  spec.authors = ['InfraBlocks Maintainers']
  spec.email = ['maintainers@infrablocks.io']

  spec.date = '2017-01-31'
  spec.summary = 'Rake tasks for managing build dependencies.'
  spec.description = 'Provides rake tasks for downloading and extracting tools depended on for further build activities.'
  spec.homepage = 'https://github.com/infrablocks/rake_dependencies'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(bin|lib|CODE_OF_CONDUCT\.md|confidante\.gemspec|Gemfile|LICENSE\.txt|Rakefile|README\.md)})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'rake_factory', '~> 0.23'
  spec.add_dependency 'hamster', '~> 3.0'
  spec.add_dependency 'rubyzip', '>= 1.3'
  spec.add_dependency 'minitar', '~> 0.9'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake_circle_ci'
  spec.add_development_dependency 'rake_github'
  spec.add_development_dependency 'rake_ssh'
  spec.add_development_dependency 'rake_gpg'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'gem-release'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'fakefs'
  spec.add_development_dependency 'simplecov'
end
