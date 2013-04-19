# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis-browser/version'

Gem::Specification.new do |spec|
  spec.name          = "redis-browser"
  spec.version       = RedisBrowser::VERSION
  spec.authors       = ["Tymon Tobolski"]
  spec.email         = ["i@teamon.eu"]
  spec.description   = %q{Simple redis browser}
  spec.summary       = %q{Simple redis browser}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

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
