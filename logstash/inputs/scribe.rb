# encoding: utf-8
require 'java'
require 'base64'
require "logstash/namespace"
require "logstash/event"
require "logstash/inputs/base"
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname

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

ARABIC_NUMBERS = Base64.decode64("2aDZodmi2aPZpNml2abZp9mo2ak=").force_encoding('UTF-8')

class LogStash::Inputs::Scribe < LogStash::Inputs::Base
  class ScribeHandler < ActionScribeHandler
    # due to jruby bug, classes that subclass java classes cannot have constructor with different number of arguments
    # therefor we use a setter instead of simply assigning in a constructor
    attr_accessor :output_queue

    def action(messages)
      messages.each do |message|
        text = message.getMessage().tr(ARABIC_NUMBERS, '0123456789').encode('UTF-8', :invalid => :replace, :undef => :replace)
        event = LogStash::Event.new({"message" => text, "category" => message.getCategory()})
        # this will block if output_queue is full. output_queue size is 20
        @output_queue << event
      end
    end

    #def action(message)
    #    event = LogStash::Event.new({"message" => message.getMessage(), "category" => message.getCategory()})
    #    @output_queue << event
    #end

    # Example for implementing "Log" directly
    # For some reason - the client does not accept the ResultCode.OK I return here
    # which is why I'm implementing "ActionScribeHandler" instead of implementing Log
    # myself. If anyone knows why this is the case - I'll be happy to know.
    # ---------------
    #java_signature 'ResultCode Log(List<LogEntry> messages)'
    #def Log(messages)
    #  messages.each do |message|
    #    event = LogStash::Event.new({"message" => message.getMessage(), "category" => message.getCategory()})
    #    @output_queue << event
    #  end
    #  return ResultCode.OK
    #end
  end

  config_name "scribe"
  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"
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
    @host = Socket.gethostname
    @logger.info("Starting scribe input listener", :address => "#{@host}:#{@port}")
  end

  def run(output_queue)
    @logger.info("Running scribe server")
    # due to jruby bug, classes that subclass java classes cannot have constructor with different number of arguments
    @handler = ScribeHandler.new(@max_in_flight_messages)
    @handler.output_queue = output_queue
    @tServer = getServer(@host, @port, @handler)
    @tServer.serve()

    # # we can abort the loop if stop? becomes true
    # while !stop?
    #   event = LogStash::Event.new("message" => @message, "host" => @host)
    #   decorate(event)
    #   queue << event
    #   # because the sleep interval can be big, when shutdown happens
    #   # we want to be able to abort the sleep
    #   # Stud.stoppable_sleep will frequently evaluate the given block
    #   # and abort the sleep(@interval) if the return value is true
    #   Stud.stoppable_sleep(@interval) { stop? }
    # end # loop

  end

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
    @interrupted = true
    @handler.drain()
    if @tServer
      @tServer.stop()
      @tServer.waitForShutdown()
    end
    finished
  end

  def teardown
    @interrupted = true
    @handler.drain()
    if @tServer
      @tServer.stop()
      @tServer.waitForShutdown()
    end
    finished
  end # def teardown
end