# frozen_string_literal: true

require_relative 'lib/mcsmp/version'
# TODO: actually make this thingy work
Gem::Specification.new do |spec|
  spec.name          = 'mcsmp'
  spec.version       = MCSMP::VERSION
  spec.authors       = ['System.rat']
  spec.email         = ['system.rodent@gmail.com']

  spec.summary       = 'Connector for the MineCraft Server management platform'
  spec.description   = 'Connector for the MineCraft Server management platform'
  spec.homepage      = 'https://github.com/System-rat/'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')


  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  # into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
