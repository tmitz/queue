# SongkickQueue

A gem for processing tasks asynchronously, powered by RabbitMQ.

![Build status](https://travis-ci.org/songkick/songkick_queue.svg?branch=master)

## Dependencies

* Ruby 2.0+
* RabbitMQ ~v2.8

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

You must define both the AMQP URL and a logger instance:

```ruby
SongkickQueue.configure do |config|
  config.amqp = 'amqp://localhost:5672'
  config.logger = Logger.new(STDOUT)
end
```

### Creating consumers

To create a consumer simply construct a new class and include the `SongkickQueue::Consumer`
module.

Consumers must declare a queue name to consume from (by calling `consume_from_queue`) and
and define a `#process` method which receives a message.

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
  rescue StandardError => e
    logger.error(e)
  end
end
```

Consumers have the logger you declared in the configuration available to them.

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

Both the `--require` and `--consumer` arguments can be passed multiple times, for example to run
multiple consumers in one process.

Example usage:

```sh
$ songkick_queue -r ./lib/environment.rb -c TweetConsumer -n notifications_worker
```

```sh
$ ps aux | grep 'notifications_worker'
22320   0.0  0.3  2486900  25368 s001  S+    4:59pm   0:00.84 notifications_worker[idle]
```

### Publishing messages

To publish messages for consumers, call the `#publish` method on `SongkickQueue`, passing in the
name of the queue to publish to and the message to send.

The queue name must match one declared in a consumer by calling `consume_from_queue`.

The message can be any primitive Ruby object that can be serialized into JSON. Messages are
serialized whilst enqueued and deserialized for being passed to the `#process` method in your
consumer.

```ruby
SongkickQueue.publish('notifications-service.tweets', { text: 'Hello world', user_id: 57237722 })
```

## Tests

See the current build status on Travis CI: https://travis-ci.org/songkick/songkick_queue

The tests are written in RSpec. Run them by calling:

```sh
$ rspec
```

## Documentation

Up to date docs are available on RubyDoc: http://www.rubydoc.info/github/songkick/songkick_queue

The documentation is written inline in the source code and processed using YARD. To generate and
view the documentation locally, run:

```sh
$ yardoc
$ yard server --reload

$ open http://localhost:8808/
```

## TODO

* Add a message UUID when publishing (add to process name when processing)
* Look at adding acknowledgement, along with #requeue and #reject methods in consumer mixin

## Contributing

Pull requests are welcome!

1. Fork it ( https://github.com/songkick/songkick_queue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
