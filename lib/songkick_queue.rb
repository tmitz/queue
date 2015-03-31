require 'json'
require 'securerandom'
require 'bunny'

require 'songkick_queue/version'
require 'songkick_queue/client'
require 'songkick_queue/consumer'
require 'songkick_queue/producer'
require 'songkick_queue/worker'
require 'songkick_queue/cli'

module SongkickQueue
  Configuration = Struct.new(:amqp, :logger, :queue_namespace)
  ConfigurationError = Class.new(StandardError)

  # Retrieve configuration for SongkickQueue
  #
  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Yields a block, passing the memoized configuration instance
  #
  # @yield [Configuration]
  def self.configure
    yield(configuration)
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
