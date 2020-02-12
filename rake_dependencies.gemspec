# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_dependencies/version'

Gem::Specification.new do |spec|
  spec.name = 'rake_dependencies'
  spec.version = RakeDependencies::VERSION
  spec.authors = ['Toby Clemson']
  spec.email = ['tobyclemson@gmail.com']

  spec.date = '2017-01-31'
  spec.summary = 'Rake tasks for managing build dependencies.'
  spec.description = 'Provides rake tasks for downloading and extracting tools depended on for further build activities.'
  spec.homepage = 'https://github.com/tobyclemson/rake_dependencies'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'rake_factory', '~> 0.23'
  spec.add_dependency 'hamster', '~> 3.0'
  spec.add_dependency 'rubyzip', '>= 1.3'
  spec.add_dependency 'minitar', '~> 0.9'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'gem-release', '~> 2.1'
  spec.add_development_dependency 'activesupport', '>= 4'
  spec.add_development_dependency 'fakefs', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.17'
end
