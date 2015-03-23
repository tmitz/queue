require "json"
require "logger"

require "bunny"

require "songkick_queue/version"
require "songkick_queue/configuration"
require "songkick_queue/client"
require "songkick_queue/consumer"
require "songkick_queue/producer"
require "songkick_queue/worker"
require "songkick_queue/cli"

module SongkickQueue
  ConfigurationError = Class.new(StandardError)

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
    raise "SongkickQueue requires a logger" unless configuration.logger
  end

  def self.publish(queue_name, message)
    producer.publish(queue_name, message)
  end

  private

  def self.producer
    @producer ||= Producer.new
  end
end
