module SongkickQueue
  class Configuration
    attr_accessor :amqp
    attr_accessor :logger

    def initialize
      @logger = Logger.new('/dev/null')
    end
  end
end
