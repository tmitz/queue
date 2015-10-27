# SongkickQueue

A gem for processing tasks asynchronously, powered by RabbitMQ.

[![Rubygems](https://badge.fury.io/rb/songkick_queue.svg)](https://rubygems.org/gems/songkick_queue)
[![Build status](https://travis-ci.org/songkick/queue.svg?branch=master)](https://travis-ci.org/songkick/queue)

## Dependencies

* Ruby 2.0+
* RabbitMQ 3.3+

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

Configure a logger and your AMQP connection settings as follows. The values defined below are the defaults:

```ruby
SongkickQueue.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.host = '127.0.0.1'
  config.port = 5672
  config.username = 'guest'
  config.password = 'guest'
  config.vhost = '/'
  config.max_reconnect_attempts = 10
  config.network_recovery_interval = 1.0
end
```

SongkickQueue should work out the box with a new, locally installed RabbitMQ instance.

NB. The `vhost` option can be a useful way to isolate environments that share the same RabbitMQ instance (eg. staging and production).

### Creating consumers

To create a consumer simply construct a new class and include the `SongkickQueue::Consumer`
module.

Consumers must declare a queue name to consume from (by calling `consume_from_queue`) and
define a `#process` method which receives a message.

For example:

```ruby
class TweetConsumer
  include SongkickQueue::Consumer

  consume_from_queue 'notifications-service.tweets'

  def process(message)
    logger.info "Received message: #{message.inspect}"

    TwitterClient.send_tweet(message[:text], message[:user_id])
  rescue TwitterClient::HttpError => e
    logger.warn(e)
  end
end
```

Consumers have the logger you declared in the configuration available to them.

### Running consumers

Run the built in binary:

```sh
$ songkick_queue --help
Usage: songkick_queue [options]
    -r, --require LIBRARY            Path to require LIBRARY. Usually this will be a file that
                                     requires some consumers
    -c, --consumer CLASS_NAME        Register consumer with CLASS_NAME
    -n, --name NAME                  Set the process name to NAME
    -h, --help                       Show this message
```

Both the `--require` and `--consumer` arguments can be passed multiple times, enabling you to run
multiple consumers in one process.

Example usage:

```sh
$ songkick_queue -r ./lib/environment.rb -c TweetConsumer -n notifications_worker
```

```sh
$ ps aux | grep 'notifications_worker'
22320   0.0  0.3  2486900  25368 s001  S+    4:59pm   0:00.84 notifications_worker[idle]
```

NB. The `songkick_queue` process does not daemonize. We recommend running it using something like
[supervisor](http://supervisord.org/) or [god](http://godrb.com/).

### Publishing messages

To publish messages for consumers, call the `#publish` method on `SongkickQueue`, passing in the
name of the queue to publish to and the message to send.

The queue name must match one declared by `consume_from_queue` in a consumer.

The message can be any primitive Ruby object that can be serialized into JSON. Messages are
serialized whilst enqueued and deserialized before being passed to the `#process` method in your
consumer.

```ruby
SongkickQueue.publish('notifications-service.tweets', { text: 'Hello world', user_id: 57237722 })
```

## Instrumentation

Hooks are provided to instrument producing and consuming of messages using [ActiveSupport's Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) API.

You can subscribe to the following events:

```
consume_message.songkick_queue
produce_message.songkick_queue
```

For both events, the payload includes the message id, produced at timestamp and queue name. The `consume_message` event also includes the consumer class.

For example:

```ruby
ActiveSupport::Notifications.subscribe('consume_message.songkick_queue') do |name, start, finish, id, payload|
  # Log info to statsd or something similar
end
```

## Tests

See the current build status on Travis CI: https://travis-ci.org/songkick/queue

The tests are written in RSpec. Run them by calling:

```sh
$ rspec
```

## Documentation

Up to date docs are available on RubyDoc: http://www.rubydoc.info/github/songkick/queue

The documentation is written inline in the source code and processed using YARD. To generate and
view the documentation locally, run:

```sh
$ yardoc
$ yard server --reload

$ open http://localhost:8808/
```

## TODO

* Add a message UUID when publishing (add to process name when processing)
* Look at adding #requeue and #reject methods in consumer mixin

## Contributing

Pull requests are welcome!

1. Fork it ( https://github.com/songkick/queue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
