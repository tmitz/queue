require "songkick_queue/version"
require "songkick_queue/configuration"
require "songkick_queue/cli"
require "songkick_queue/worker"

require "bunny"

module SongkickQueue
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
