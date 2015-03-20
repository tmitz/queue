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
  end

  def self.publish(queue_name, message)
    @producer ||= Producer.new
    @producer.publish(queue_name, message)
  end
end
