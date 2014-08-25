lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |s|
  s.name        = 'talk'
  s.executables << 'maketalk'
  s.version     = Talk::VERSION
  s.date        = '2014-06-12'
  s.summary     = "Compile-to-source protocol contract specification language"
  s.description = "A lightweight language for specifying protocol contracts. Compiles to source in Java, CSharp, Javascript, ObjC and Ruby."
  s.authors     = ["Jonas Acres"]
  s.email       = 'jonas@becuddle.com'
  s.homepage    = 'http://github.com/jonasacres/talk'
  s.license     = 'GPLv2'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'trollop', "~> 2.0"
  s.add_runtime_dependency 'uglifier', "~> 2.2.1"
  s.add_runtime_dependency 'therubyracer', "~> 0.12.1"

end
