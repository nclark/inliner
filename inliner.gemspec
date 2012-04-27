Gem::Specification.new do |s|
  s.name        = 'inliner'
  s.version     = '0.0.0'
  s.date        = '2012-04-27'
  s.summary     = "Inlines assets from a URL."
  s.description = s.summary
  s.authors     = ["Mark Sonnabaum"]
  s.email       = 'mark@sonnabaum.com'
  s.files       = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
end
