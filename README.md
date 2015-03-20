# SongkickQueue

A gem for processing tasks asynchronously, powered by RabbitMQ.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'songkick_queue'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install songkick_queue

## Usage

### Setup

```ruby
SongkickQueue.configure do |config|
  config.amqp = 'amqp://localhost:5672'
  config.logger = Logger.new(STDOUT)
end
```

### Creating consumers

```ruby
class TweetConsumer
  include SongkickQueue::Consumer

  consume_from_queue 'notifications-service.tweets'

  def process(message)
    set_message_name(message[:user_id])
    logger.info "Received message: #{message.inspect}"

    TwitterClient.send_tweet(message[:text], message[:user_id])
  rescue TwitterClient::HttpError => e
    logger.warn(e)

    requeue!
  rescue StandardError => e
    logger.error(e)

    reject!
  end
end
```

### Running consumers

Run the built in binary:

    $ bin/songkick_consumer --require 'lib/environment' -n "notifications"

The process name of the worker will be "notifications" when idle or
"notifications-TweetConsumer[234]" when processing a job.

Or make your own:

```ruby
#!/usr/bin/env ruby

require 'lib/environment'
require 'songkick_queue'

SongkickQueue::CLI.new(ARGV).run
```

### Publishing messages

```ruby
SongkickQueue.publish('notifications-service.tweets', { text: 'Hello world', user_id: 57237722 })
```
