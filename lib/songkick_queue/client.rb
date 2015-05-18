module SongkickQueue
  class Client
    def default_exchange
      channel.default_exchange
    end

    # Creates a memoized channel for issuing RabbitMQ commands
    #
    # @return [Bunny::Channel]
    def channel
      @channel ||= build_channel
    end

    # Creates a memoized connection to RabbitMQ
    #
    # @return [Bunny::Session]
    def connection
      @connection ||= build_connection
    end

    private

    def build_channel
      channel = connection.create_channel
      channel.prefetch(1)

      channel
    end

    def build_connection
      connection = Bunny.new(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        vhost: config.vhost,
        heartbeat_interval: 10,
        automatically_recover: true,
        network_recovery_interval: config.network_recovery_interval,
        recover_from_connection_close: true,
      )

      connection.start

      connection
    end

    def config
      SongkickQueue.configuration
    end
  end
end
