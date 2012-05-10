# -*- encoding: utf-8 -*-
require File.expand_path('../lib/inliner/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Sonnabaum"]
  gem.email         = ["mark@sonnabaum.com"]
  gem.summary       = %q{Inlines assets from a URL.}
  gem.description   = gem.summary
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "inliner"
  gem.require_paths = ["lib"]
  gem.version       = Inliner::VERSION
  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('aruba')
  gem.add_development_dependency('rake','~> 0.9.2')
  gem.add_dependency('nokogiri','~> 1.5.2')
  gem.add_dependency('rack','~> 1.4.1')
  gem.add_dependency('em-http-request', '~> 1.0.2')
  gem.add_dependency('methadone', '~>1.0.0.rc4')
end
