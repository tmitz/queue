module SongkickQueue
  class Producer
    def initialize
      @client = Client.new
    end

    def publish(queue_name, message)
      payload = JSON.dump(message)

      client
        .default_exchange
        .publish(payload, routing_key: String(queue_name))
    end

    private

    attr_reader :client
  end
end
