require_relative 'lib/quadtone/version'

Gem::Specification.new do |s|
  s.name        = 'qttk'
  s.version     = Quadtone::VERSION
  s.author      = 'John Labovitz'
  s.email       = 'johnl@johnlabovitz.com'
  s.homepage    = 'http://github.com/jslabovitz/qttk'
  s.summary     = %q{Tools for working with the quadtone printing process}
  s.description = %q{
    Quadtone Toolkit (QTTK): Tools for working with the quadtone printing process.
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'builder', '~> 3.2'
  s.add_dependency 'path', '~> 2.0'
  s.add_dependency 'rmagick', '~> 2.16'
  s.add_dependency 'ffi', '~> 1.9'
  s.add_dependency 'cupsffi', '~> 0.1'
  s.add_dependency 'hashstruct', '~> 1.3'
  s.add_dependency 'descriptive_statistics', '~> 2.5'
  s.add_dependency 'spliner', '~> 1.0'

  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
end