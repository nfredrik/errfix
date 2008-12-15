require 'rubygems'
SPEC = Gem::Specification.new do |s|
	s.name = "errfix"
	s.version = "0.1.2"
	s.author = "Peter Houghton"
	s.email = ""
	s.homepage = "http://code.google.com/p/errfix/"
	s.platform = Gem::Platform::RUBY
	s.summary = "Model Based Testing with Ruby"
	candidates = Dir.glob("{docs,lib,test}/**/*")
	s.files	= candidates.delete_if do |item|
		item.include?("SVN") || item.include?("rdoc")
	end
	s.require_path = "lib"
	s.autorequire = "errfix"
	s.test_file = "test/test_runner.rb"
	s.has_rdoc = true
end
	
