all:
	mvn clean compile assembly:single
	gem build logstash-input-scribe.gemspec
