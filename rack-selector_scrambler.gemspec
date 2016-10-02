# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/selector_scrambler/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-selector_scrambler"
  spec.version       = Rack::SelectorScrambler::VERSION
  spec.authors       = ["Daniel Bryant"]
  spec.email         = ["bryant.daniel.j@gmail.com"]

  spec.summary       = %q{Rack middleware to randomize HTML selectors in HTML, CSS, and JavaScript source.}
  spec.homepage      = "https://github.com/daniel-bryant/rack-selector_scrambler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rack", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
