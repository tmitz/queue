module SongkickQueue
  class Worker
    attr_reader :process_name, :consumer_classes

    # @param process_name [String] of the custom process name to use
    # @param consumer_classes [Array<Class>, Class] of consumer class names
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
        arguments: { 'x-ha-policy' => 'all' })

      queue.subscribe(manual_ack: true) do |delivery_info, properties, message|
        process_message(consumer_class, delivery_info, properties, message)
      end

      logger.info "Subscribed #{consumer_class} to #{consumer_class.queue_name}"
    end

    # Handle receipt of a subscribed message
    #
    # @param consumer_class [Class] that was subscribed to
    # @param delivery_info [Bunny::DeliveryInfo]
    # @param properties [Bunny::MessageProperties]
    # @param message [String] to deserialize
    def process_message(consumer_class, delivery_info, properties, message)
      message = JSON.parse(message, symbolize_names: true)

      message_id = message.fetch(:message_id)
      produced_at = message.fetch(:produced_at)
      payload = message.fetch(:payload)

      logger.info "Processing message #{message_id} via #{consumer_class}, produced at #{produced_at}"
      set_process_name(consumer_class, message_id)

      consumer = consumer_class.new(delivery_info, logger)

      instrumentation_options = {
        consumer_class: consumer_class.to_s,
        queue_name: consumer_class.queue_name,
        message_id: message_id,
        produced_at: produced_at,
      }
      ActiveSupport::Notifications.instrument('consume_message.songkick_queue', instrumentation_options) do
        consumer.process(payload)
      end
    rescue Object => exception
      logger.error(exception)
    ensure
      set_process_name
      channel.ack(delivery_info.delivery_tag, false)
    end

    def channel
      client.channel
    end

    def logger
      config.logger
    end

    def config
      SongkickQueue.configuration
    end

    # Update the name of this process, as viewed in `ps` or `top`
    #
    # @example idle
    #   set_process_name #=> "songkick_queue[idle]"
    # @example consumer running, namespace is removed
    #   set_process_name(Foo::TweetConsumer, 'a729bcd8') #=> "songkick_queue[TweetConsumer#a729bcd8]"
    # @param status [String] of the program
    # @param message_id [String] identifying the message currently being consumed
    def set_process_name(status = 'idle', message_id = nil)
      formatted_status = String(status)
        .split('::')
        .last

      ident = [formatted_status, message_id]
        .compact
        .join('#')

      $PROGRAM_NAME = "#{process_name}[#{ident}]"
    end
  end
end
