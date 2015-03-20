require_relative '../lib/songkick_queue'
require 'logger'

SongkickQueue.configure do |config|
  config.amqp = 'amqp://localhost:5672'
  config.logger = Logger.new(STDOUT)
end

class TweetConsumer
  # This should be defined be calling consumer_from_queue (see README for example)
  def self.queue_name
    'tweets-queue'
  end

  def process(payload)
    puts "TweetConsumer#process(#{payload})"
  end
end

worker = SongkickQueue::Worker.new(TweetConsumer)
worker.run
