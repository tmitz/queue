# Example consumer
# Require this file when running `songkick_queue` like so:
#
#   $ bin/songkick_queue --require ./examples/consumer.rb --consumer TweetConsumer
#
require_relative '../lib/songkick_queue'

SongkickQueue.configure do |config|
  config.host = 'localhost'
  config.logger = Logger.new(STDOUT)
end

class TweetConsumer
  include SongkickQueue::Consumer

  consume_from_queue 'notifications-service.tweets'

  def process(payload)
    puts "TweetConsumer#process(#{payload})"

    10.times do
      sleep 1
      puts "Processing..."
    end

    puts "Done processing!"
  end
end
