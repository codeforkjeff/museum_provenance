# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'museum_provenance/version'

Gem::Specification.new do |spec|
  spec.name          = "museum_provenance"
  spec.version       = MuseumProvenance::VERSION
  spec.authors       = ["David Newbury"]
  spec.email         = ["david.newbury@gmail.com"]
  spec.summary       = %q{A library for extracting structured data from museum provenance records.}
  spec.description   = %q{museum_provenance is a Ruby library developed to help cultural institutions manage and understand the provenance of the objects within their collection. It does this by parsing semi-structured provenance texts into structured data.  Developed as part of the Art Tracks project at the Carnegie Museum of Art.}
  spec.homepage      = "http://museumprovenance.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.has_rdoc = 'yard'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'

  spec.add_runtime_dependency 'date_time_precision'
  spec.add_runtime_dependency 'chronic'
  spec.add_runtime_dependency 'activesupport', '~> 4.1.6'
end
