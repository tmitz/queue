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
  spec.homepage      = "https://git.songkick.net/?p=songkick-queue.git;a=tree"
  spec.license       = ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "bunny", "~> 1.7"
end
