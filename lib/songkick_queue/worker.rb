require 'thread'

module SongkickQueue
  class Worker
    attr_reader :consumer_classes

    def initialize(consumer_classes = [])
      @consumer_classes = Array(consumer_classes)

      if @consumer_classes.empty?
        fail ArgumentError, 'no consumer classes given to Worker'
      end

      @subscribers = []
    end

    def run
      consumer_classes.each do |consumer_class|
        subscribe_to_queue(consumer_class)
      end

      setup_signal_catching
      stop_if_signal_caught

      channel.work_pool.join
    end

    def setup_signal_catching
      trap('INT') { @shutdown = 'INT' }
      trap('TERM') { @shutdown = 'TERM' }
    end

    def stop_if_signal_caught
      Thread.new do
        loop do
          sleep 1

          if @shutdown
            logger.info "Recevied SIG#{@shutdown}, shutting down consumers"

            @subscribers.each { |subscriber| subscriber.cancel }
            @channel.close
            @connection.close
          end
        end
      end
    end

    def subscribe_to_queue(consumer_class)
      queue = channel.queue(consumer_class.queue_name, durable: true,
        arguments: {'x-ha-policy' => 'all'})

      consumer = consumer_class.new

      @subscribers << queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
        begin
          consumer.process(payload)
          channel.ack(delivery_info.delivery_tag, false)
        rescue Object => exception
          logger.error(exception)
        end
      end
    end

    def channel
      @channel ||= begin
        channel = connection.create_channel
        channel.prefetch(1)

        channel
      end
    end

    def connection
      @connection ||= begin
        connection = Bunny.new(config.amqp)
        connection.start

        connection
      end
    end

    def logger
      config.logger || Logger.new('/dev/null')
    end

    def config
      SongkickQueue.configuration
    end
  end
end
