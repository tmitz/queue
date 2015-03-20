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

```sh
$ songkick_queue --help
Usage: songkick_consumer [options]
    -r, --require LIBRARY            Path to require LIBRARY. Usually this will be a file that
                                     requires some consumers
    -c, --consumer CLASS_NAME        Register consumer with CLASS_NAME
    -n, --name NAME                  Set the process name to NAME
    -h, --help                       Show this message
```

Example usage:

```sh
$ songkick_queue -r ./lib/environment.rb -c TweetConsumer -n notifications_worker
```

```sh
$ ps aux | grep 'tweet_worker'
22320   0.0  0.3  2486900  25368 s001  S+    4:59pm   0:00.84 notifications_worker[idle]
```

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
