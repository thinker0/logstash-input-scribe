Gem::Specification.new do |s|
  s.name = 'logstash-input-scribe'
  s.version = '0.1.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = "A logstash input plugin which receives scribe log entries via thrift"
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Daniel Pañeda"]
  s.email = 'dpaneda@tuenti.com'
  s.homepage = "https://github.com/EverythingMe/logstash-scribeinput"
  s.require_paths = ["lib"]

  s.platform = "java"

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.requirements << "jar 'me.everything:scribe_server', '0.1.0'"
  s.add_runtime_dependency 'jar-dependencies'
  # s.add_runtime_dependency 'extracted_library'
  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0", "< 3.0.0"
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  # avoids to install it on the fly when jar-dependencies needs it
  s.add_development_dependency 'ruby-maven', '~> 3.3', '>= 3.3.8'
  s.add_development_dependency 'logstash-devutils'
  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }
end
