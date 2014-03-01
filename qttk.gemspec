# -*- encoding: utf-8 -*-

$LOAD_PATH << File.expand_path('../lib', __FILE__)

# require 'qttk/version'

Gem::Specification.new do |s|
  s.name        = 'qttk'
  s.version     = '0.1.0'   # QTTK::VERSION
  s.author      = 'John Labovitz'
  s.email       = 'johnl@johnlabovitz.com'
  s.homepage    = 'http://github.com/jslabovitz/qttk'
  # s.rubyforge_project = 'qttk'
  s.summary     = %q{Tools for working with the quadtone printing process}
  s.description = %q{
    Quadtone Toolkit (QTTK): Tools for working with the quadtone printing process.
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'builder'
  s.add_dependency 'pathname3'
  s.add_dependency 'rmagick'
  s.add_dependency 'cupsffi'
  s.add_dependency 'hashstruct'
  
  # s.add_development_dependency 'minitest'
  # s.add_development_dependency 'wrong'
end