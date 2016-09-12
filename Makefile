all:
	mvn clean compile assembly:single
	gem build logstash-input-scribe.gemspec
	mkdir -p generated
	mv *.gem target/*.jar generated
