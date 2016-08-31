# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis-browser/version'

Gem::Specification.new do |spec|
  spec.name          = "redis-browser"
  spec.version       = RedisBrowser::VERSION
  spec.authors       = ["Tymon Tobolski", "Michał Szajbe"]
  spec.email         = ["michal.szajbe@gmail.com"]
  spec.description   = %q{Web-based Redis browser that can work as standalone app or mounted Rails engine.}
  spec.summary       = %q{Web-based Redis browser}
  spec.homepage      = "http://github.com/humante/redis-browser"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">=1.9.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "sinatra"
  spec.add_runtime_dependency "sinatra-contrib"
  spec.add_runtime_dependency "slim"
  spec.add_runtime_dependency "sass"
  spec.add_runtime_dependency "coffee-script"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "redis"
end
