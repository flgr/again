# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "again/version"

Gem::Specification.new do |s|
  s.name        = "again"  
  s.version     = Again::VERSION

  s.authors     = ["Florian Gross"]
  s.email       = ["Florian.S.Gross@web.de"]
  s.homepage    = "https://github.com/flgr/again"
  s.summary     = %q{The best way to iteratively develop with Ruby}
  s.description = %q{again automatically reloads your application's code when it changes}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = [] # `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "listen"
end
