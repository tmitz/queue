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

      client
        .default_exchange
        .publish(payload, routing_key: String(queue_name))
    end

    private

    attr_reader :client
  end
end
