# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "repository/version"

Gem::Specification.new do |s|
  s.name          = "repository"
  s.version       = Repository::VERSION
  s.authors       = ["Kieran Gibb"]
  s.email         = ["kieran@tenthousandthings.org.uk"]
  s.summary       = "An implementation of the Repository pattern persisting to YAML, JSON or CSV files"
  s.description   = "Repository is a relational database allowing for you to model, validate and run callbacks on your classes and persist the data to YAML, JSON or CSV."

  s.homepage      = "https://github.com/kgibb8/repository"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f)  }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "json"
  s.add_runtime_dependency "csv"

  s.add_development_dependency "bundler", "~> 1.15"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rs", "~> 3.0"
  s.add_development_dependency "pry-byebug"
end
