require 'json'
require 'securerandom'
require 'logger'
require 'bunny'
require 'time'
require 'active_support/notifications'

require 'songkick_queue/version'
require 'songkick_queue/client'
require 'songkick_queue/consumer'
require 'songkick_queue/producer'
require 'songkick_queue/worker'
require 'songkick_queue/cli'

module SongkickQueue
  Configuration = Struct.new(
    :logger,
    :host,
    :port,
    :username,
    :password,
    :vhost,
    :max_reconnect_attempts,
    :network_recovery_interval,
  )

  TooManyReconnectAttemptsError = Class.new(StandardError)

  # Retrieve configuration for SongkickQueue
  #
  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new.tap do |config|
      config.logger = Logger.new(STDOUT)
      config.port = 5672
      config.max_reconnect_attempts = 10
      config.network_recovery_interval = 1.0
    end
  end

  # Yields a block, passing the memoized configuration instance
  #
  # @yield [Configuration]
  def self.configure
    yield(configuration)

    configuration
  end

  # Publishes the given message to the given queue
  #
  # @see SongkickQueue::Producer#publish for argument documentation
  def self.publish(queue_name, message, options = {})
    producer.publish(queue_name, message, options = {})
  end

  private

  def self.producer
    @producer ||= Producer.new
  end
end
