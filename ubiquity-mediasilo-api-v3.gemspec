# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ubiquity/mediasilo/api/v3/version'

Gem::Specification.new do |spec|
  spec.name          = 'ubiquity-mediasilo-api-v3'
  spec.version       = Ubiquity::MediaSilo::API::V3::VERSION
  spec.authors       = ['John Whitson']
  spec.email         = ['john.whitson@gmail.com']
  spec.summary       = %q{A Library and Utilities to Interact with the MediaSilo API v3}
  spec.description   = %q{}
  spec.homepage      = 'https://github.com/XPlatform-Consulting/ubiquity-mediasilo-api-v3'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
end
