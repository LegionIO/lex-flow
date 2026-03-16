# frozen_string_literal: true

require_relative 'lib/legion/extensions/flow/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-flow'
  spec.version       = Legion::Extensions::Flow::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Flow state detection and management for LegionIO cognitive agents'
  spec.description   = 'Detects and manages psychological flow states based on challenge-skill balance'
  spec.homepage      = 'https://github.com/LegionIO/lex-flow'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.add_development_dependency 'legion-gaia'
end
