# Example producer
# Run this file like so:
#
#   $ bundle exec ruby examples/producer.rb
#
require_relative '../lib/songkick_queue'

SongkickQueue.configure do |config|
  config.host = 'localhost'
  config.logger = Logger.new(STDOUT)
end

ActiveSupport::Notifications.subscribe('produce_message.songkick_queue') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  SongkickQueue.configuration.logger.info "name: #{event.name}, duration: #{event.duration}, payload: #{event.payload}"
end

3.times do
  SongkickQueue.publish('notifications-service.tweets', { text: 'Hello world', user_id: 57237722 })
end
