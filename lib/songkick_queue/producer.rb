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
    def publish(queue_name, message)
      payload = JSON.generate(message)

      routing_key = [config.queue_namespace, queue_name].compact.join('.')

      client
        .default_exchange
        .publish(payload, routing_key: routing_key)
    end

    private

    def config
      SongkickQueue.configuration
    end

    attr_reader :client
  end
end
