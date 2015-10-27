# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'songkick_queue/version'

Gem::Specification.new do |spec|
  spec.name          = "songkick_queue"
  spec.version       = SongkickQueue::VERSION
  spec.authors       = ["Dan Lucraft", "Paul Springett"]
  spec.email         = ["dan.lucraft@songkick.com", "paul.springett@songkick.com"]
  spec.summary       = %q{A gem for processing tasks asynchronously, powered by RabbitMQ.}
  spec.description   = %q{A gem for processing tasks asynchronously, powered by RabbitMQ.}
  spec.homepage      = "https://github.com/songkick/songkick_queue"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "yard"

  # Used by yardoc for processing README.md code snippets
  spec.add_development_dependency "redcarpet"

  spec.add_dependency "bunny", "~> 2.2"
  spec.add_dependency "activesupport", ">= 3.0.0"
end
