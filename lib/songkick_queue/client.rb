module SongkickQueue
  class Client
    def default_exchange
      channel.default_exchange
    end

    # Creates a memoized channel for issuing RabbitMQ commands
    #
    # @return [Bunny::Channel]
    def channel
      @channel ||= begin
        channel = connection.create_channel
        channel.prefetch(1)

        channel
      end
    end

    # Creates a memoized connection to RabbitMQ
    #
    # @return [Bunny::Session]
    def connection
      @connection ||= begin
        connection = Bunny.new(
          host: config.host,
          port: config.port,
          username: config.username,
          password: config.password,
          vhost: config.vhost,
          heartbeat_interval: 60,
        )

        connection.start

        connection
      end
    end

    private

    def config
      SongkickQueue.configuration
    end
  end
end
