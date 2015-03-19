require "songkick/consumer/version"
require "songkick/consumer/configuration"
require "songkick/consumer/cli"
require "songkick/consumer/worker"

require "bunny"

module Songkick
  module Consumer

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end

  end
end
