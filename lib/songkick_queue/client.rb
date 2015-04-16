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
        connection = Bunny.new(config_amqp, heartbeat_interval: 60)
        connection.start

        connection
      end
    end

    private

    # Retrieve the AMQP URL from the configuration
    #
    # @raise [ConfigurationError] if not defined
    def config_amqp
      config.amqp || fail(ConfigurationError, 'missing AMQP URL from config')
    end

    def config
      SongkickQueue.configuration
    end
  end
end
