all:
	mvn clean compile assembly:single
	mkdir -p vendor
	mv target/*.jar vendor/jar-dependencies/runtime-jars/
	gem build logstash-input-scribe.gemspec
	mkdir -p generated
	mv *.gem generated
