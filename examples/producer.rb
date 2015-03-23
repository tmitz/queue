require_relative '../lib/songkick_queue'

SongkickQueue.configure do |config|
  config.amqp = 'amqp://localhost:5672'
  config.logger = Logger.new(STDOUT)
end

3.times do
  SongkickQueue.publish('notifications-service.tweets', { text: 'Hello world', user_id: 57237722 })
end
