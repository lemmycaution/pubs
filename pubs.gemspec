# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pubs/version'

Gem::Specification.new do |spec|
  spec.name          = "pubs"
  spec.version       = Pubs::VERSION
  spec.authors       = ["Onur Uyar"]
  spec.email         = ["me@onuruyar.com"]
  spec.description   = %q{Pubs IO Private Library}
  spec.summary       = %q{Pubs IO Private Library}
  spec.homepage      = "http://www.pubs.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  # Data
  spec.add_runtime_dependency "pg"
  spec.add_runtime_dependency "activerecord", "~> 4.0.0"
  spec.add_runtime_dependency "bcrypt-ruby", "~> 3.1.2"
  spec.add_runtime_dependency "dalli", "~> 2.6.4"
  spec.add_runtime_dependency "surus"
  spec.add_runtime_dependency "pg_search"

  # Server
  spec.add_runtime_dependency "goliath", "~> 1.0.3"
  spec.add_runtime_dependency "foreman"

  # Support
  spec.add_runtime_dependency "i18n"
  spec.add_runtime_dependency "tilt"
  spec.add_runtime_dependency "activesupport", "~> 4.0.0"
  spec.add_runtime_dependency "oj"
  spec.add_runtime_dependency 'em-http-request'
  spec.add_runtime_dependency 'heroku'
  spec.add_runtime_dependency 'heroku-api'
  spec.add_runtime_dependency 'mail'
  spec.add_runtime_dependency 'aescrypt'

end
