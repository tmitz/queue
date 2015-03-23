require 'thread'

module SongkickQueue
  class Worker
    attr_reader :process_name, :consumer_classes

    # @param process_name [String] of the custom process name to use
    # @param consumer_classes, [Array<Class>, Class] of consumer class names
    def initialize(process_name, consumer_classes = [])
      @process_name = process_name
      @consumer_classes = Array(consumer_classes)

      if @consumer_classes.empty?
        fail ArgumentError, 'no consumer classes given to Worker'
      end

      @client = Client.new
    end

    # Subscribes the consumers classes to their defined message queues and
    # blocks until all the work pool consumers have finished. Also sets up
    # signal catching for graceful exits no interrupt
    def run
      set_process_name

      consumer_classes.each do |consumer_class|
        subscribe_to_queue(consumer_class)
      end

      setup_signal_catching
      stop_if_signal_caught

      channel.work_pool.join
    end

    private

    attr_reader :client

    def setup_signal_catching
      trap('INT') { @shutdown = 'INT' }
      trap('TERM') { @shutdown = 'TERM' }
    end

    # Checks for presence of @shutdown every 1 second and if found instructs
    # all the channel's work pool consumers to shutdown. Each work pool thread
    # will finish its current task and then join the main thread. Once all the
    # threads have joined then `channel.work_pool.join` will cease blocking and
    # return, causing the process to terminate.
    def stop_if_signal_caught
      Thread.new do
        loop do
          sleep 1

          if @shutdown
            logger.info "Recevied SIG#{@shutdown}, shutting down consumers"

            @client.channel.work_pool.shutdown
            @shutdown = nil
          end
        end
      end
    end

    # Declare a queue and subscribe to it
    #
    # @param consumer_class [Class] to subscribe to
    def subscribe_to_queue(consumer_class)
      queue = channel.queue(consumer_class.queue_name, durable: true,
        arguments: {'x-ha-policy' => 'all'})

      queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
        process_message(consumer_class, delivery_info, properties, payload)
      end

      logger.info "Subscribed #{consumer_class} to #{consumer_class.queue_name}"
    end

    # Handle receipt of a subscribed message
    #
    # @param consumer_class [Class] that was subscribed to
    # @param delivery_info [Bunny::DeliveryInfo]
    # @param properties [Bunny::MessageProperties]
    # @param payload [String] to deserialize
    def process_message(consumer_class, delivery_info, properties, payload)
      logger.info "Processing message via #{consumer_class}..."

      set_process_name(consumer_class)

      message = JSON.parse(payload, symbolize_names: true)

      consumer = consumer_class.new(delivery_info, logger)
      consumer.process(message)
    rescue Object => exception
      logger.error(exception)
    ensure
      set_process_name
      channel.ack(delivery_info.delivery_tag, false)
    end

    def channel
      client.channel
    end

    # Retrieve the logger defined in the configuration
    #
    # @raise [ConfigurationError] if not defined
    def logger
      config.logger || fail(ConfigurationError, 'No logger configured, see README for more details')
    end

    def config
      SongkickQueue.configuration
    end

    def set_process_name(status = 'idle')
      formatted_status = String(status)
        .gsub(/([A-Z]+)/) { "_#{$1.downcase}" }
        .sub(/^_(\w)/) { $1 }

      $PROGRAM_NAME = "#{process_name}[#{formatted_status}]"
    end
  end
end
