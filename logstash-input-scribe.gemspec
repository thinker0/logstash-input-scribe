Gem::Specification.new do |s|
  s.name = 'logstash-input-scribe'
  s.version = '0.0.1'
  s.licenses = ['Apache License (2.0)']
  s.summary = "A logstash input plugin which receives scribe log entries via thrift"
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Daniel Pañeda"]
  s.email = 'dpaneda@tuenti.com'
  s.homepage = ""
  s.require_paths = ["lib"]

  s.platform = "java"

  # Files
  s.files = Dir['lib/**/*', '*.gemspec','*.md', 'Gemfile']

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0", "< 3.0.0"

  s.add_runtime_dependency 'jar-dependencies'
  s.requirements << "jar tuenti:scribe-server, 1.0"

  # avoids to install it on the fly when jar-dependencies needs it
  s.add_development_dependency 'ruby-maven', '~> 3.3', '>= 3.3.8'
end
