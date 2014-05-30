Gem::Specification.new do |s|
  s.name        = 'talk'
  s.executables << 'talk'
  s.version     = '2.0.5'
  s.date        = '2014-05-30'
  s.summary     = "Compile-to-source protocol contract specification language"
  s.description = "A lightweight language for specifying protocol contracts. Compiles to source in Java, Javascript, ObjC and Ruby."
  s.authors     = ["Jonas Acres"]
  s.email       = 'jonas@becuddle.com'
  s.homepage    = 'http://github.com/jonasacres/talk'
  s.license     = 'GPLv2'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s|features)/})
  s.require_paths = ["lib"]

end
