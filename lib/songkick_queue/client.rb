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

    def connection
      @connection ||= begin
        connection = Bunny.new(config_amqp)
        connection.start

        connection
      end
    end

    def close
      channel.close
      connection.close
    end

    private

    def config_amqp
      config.amqp || fail(ConfigurationError, 'missing AMQP URL from config')
    end

    def config
      SongkickQueue.configuration
    end
  end
end
