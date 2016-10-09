require 'java'
require 'base64'
require "logstash/namespace"
require "logstash/event"
require "logstash/inputs/base"
require 'logstash-input-scribe_jars.rb'

java_import 'scribe.thrift.ResultCode'
java_import 'scribe.thrift.Scribe'
java_import 'scribe.thrift.ActionScribeHandler'
java_import 'scribe.thrift.LogEntry'
java_import 'scribe.thrift.StdoutScribeHandler'
java_import 'org.apache.thrift.protocol.TBinaryProtocol'
java_import 'org.apache.thrift.server.TServer'
java_import 'org.apache.thrift.transport.TFramedTransport'
java_import 'org.apache.thrift.transport.TNonblockingServerSocket'
java_import 'org.apache.thrift.transport.TServerTransport'
java_import 'org.apache.thrift.transport.TTransportException'
java_import 'org.apache.thrift.server.THsHaServer'

class LogStash::Inputs::Scribe < LogStash::Inputs::Base
  class ScribeHandler < ActionScribeHandler
    # due to jruby bug, classes that subclass java classes cannot have constructor with different number of arguments
    # therefor we use a setter instead of simply assigning in a constructor
    attr_accessor :output_queue

    def action(messages)
        messages.each do |message|
            text = message.getMessage().encode('UTF-8', :invalid => :replace, :undef => :replace)
            event = LogStash::Event.new({"message" => text, "category" => message.getCategory()})
            # this will block if output_queue is full. output_queue size is 20
            @output_queue << event
        end
    end
  end

  config_name "scribe"
  milestone 1

  config :host, :validate => :string, :default => "0.0.0.0"
  config :port, :validate => :number, :required => true
  config :worker_threads, :validate => :number, :default => 4
  config :max_in_flight_messages, :validate => :number, :default => 10000

  def initialize(*args)
    super(*args)
  end

  private
  def getServer(host, port, handler)
    bindAddr = java.net.InetSocketAddress.new(host, port)
    serverArgs = THsHaServer::Args.new(TNonblockingServerSocket.new(bindAddr))
    serverArgs.processor(Scribe::Processor.new(handler))
    serverArgs.workerThreads(@worker_threads)
    serverArgs.transportFactory(TFramedTransport::Factory.new())
    serverArgs.protocolFactory(TBinaryProtocol::Factory.new(false, false))
    return THsHaServer.new(serverArgs)
  end

  public
  def register
    @logger.info("Starting scribe input listener", :address => "#{@host}:#{@port}")
  end

  def run(output_queue)
    @logger.info("Running scribe server")
    # due to jruby bug, classes that subclass java classes cannot have constructor with different number of arguments

    @handler = ScribeHandler.new(@max_in_flight_messages)
    @handler.output_queue = output_queue
    @tServer = getServer(@host, @port, @handler)
    @tServer.serve()
  end

  def stop
    @interrupted = true
    @handler.drain()
    if @tServer
      @tServer.stop()
      @tServer.waitForShutdown()
    end
  end
end 
