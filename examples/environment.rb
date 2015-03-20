require_relative '../lib/songkick_queue'
require 'logger'

SongkickQueue.configure do |config|
  config.amqp = 'amqp://localhost:5672'
  config.logger = Logger.new(STDOUT)
end

class TweetConsumer
  include SongkickQueue::Consumer

  consume_from_queue 'notifications-service.tweets'

  def process(payload)
    puts "TweetConsumer#process(#{payload})"

    3.times do
      sleep 1
      puts "Processing..."
    end

    puts "Done processing!"
  end
end
