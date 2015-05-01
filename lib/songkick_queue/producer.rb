module SongkickQueue
  class Producer
    def initialize
      @client = Client.new
    end

    # Serializes the given message and publishes it to the default RabbitMQ
    # exchange
    #
    # @param queue_name [String] to publish to
    # @param message [#to_json] to serialize and enqueue
    # @option options [String] :message_id to pass through to the consumer (will be logged)
    # @option options [String] :produced_at time when the message was created, ISO8601 formatted
    def publish(queue_name, payload, options = {})
      message_id = options.fetch(:message_id) { SecureRandom.hex(6) }
      produced_at = options.fetch(:produced_at) { Time.now.utc.iso8601 }

      message = {
        message_id: message_id,
        produced_at: produced_at,
        payload: payload
      }

      message = JSON.generate(message)

      client
        .default_exchange
        .publish(message, routing_key: queue_name)

      logger.info "Published message #{message_id} to '#{queue_name}' at #{produced_at}"
    end

    private

    # Retrieve the logger defined in the configuration
    #
    # @raise [ConfigurationError] if not defined
    def logger
      config.logger || fail(ConfigurationError, 'No logger configured, see README for more details')
    end

    def config
      SongkickQueue.configuration
    end

    attr_reader :client
  end
end
