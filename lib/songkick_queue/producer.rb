module SongkickQueue
  class Producer
    attr_accessor :reconnect_attempts

    def initialize
      @client = Client.new
      @reconnect_attempts = 0
      @publish_reconnect_delay = 5.0
    end

    # Serializes the given message and publishes it to the default RabbitMQ exchange
    #
    # @param queue_name [String] to publish to
    # @param message [#to_json] to serialize and enqueue
    # @option options [String] :message_id to pass through to the consumer (will be logged)
    # @option options [String] :produced_at time when the message was created, ISO8601 formatted
    #
    # @raise [TooManyReconnectAttemptsError] if max reconnect attempts is exceeded
    #
    # @return [Bunny::Exchange]
    def publish(queue_name, payload, options = {})
      message_id = options.fetch(:message_id) { SecureRandom.hex(6) }
      produced_at = options.fetch(:produced_at) { Time.now.utc.iso8601 }

      message = {
        message_id: message_id,
        produced_at: produced_at,
        payload: payload
      }

      message = JSON.generate(message)

      exchange = client
        .default_exchange
        .publish(message, routing_key: String(queue_name))

      self.reconnect_attempts = 0

      logger.info "Published message #{message_id} to '#{queue_name}' at #{produced_at}"

      exchange
    rescue Bunny::ConnectionClosedError
      self.reconnect_attempts += 1

      if (reconnect_attempts > config.max_reconnect_attempts)
        fail TooManyReconnectAttemptsError, "Attempted to reconnect more than " +
          "#{config.max_reconnect_attempts} times"
      end

      logger.info "Attempting to reconnect to RabbitMQ, attempt #{reconnect_attempts} " +
        "of #{config.max_reconnect_attempts}"

      wait_for_bunny_session_to_reconnect

      retry
    end

    private

    # When retrying publishing of a message after a ConnectionClosedError, we must first wait for
    # the defined network_recovery_interval and then a bit longer for it to reopen connections and
    # channels etc...
    #
    # If we attempt to publish again before the connection has been reopened we'll catch the
    # Bunny::ConnectionClosedError exception again and just use another attempt to try and connect.
    #
    # @todo Optimize this to know when the connection is open again, rather than picking an
    # arbitary time period.
    #
    # @return [void]
    def wait_for_bunny_session_to_reconnect
      wait_time = config.network_recovery_interval + publish_reconnect_delay
      sleep wait_time
    end

    def logger
      config.logger
    end

    def config
      SongkickQueue.configuration
    end

    attr_reader :client, :publish_reconnect_delay
  end
end
