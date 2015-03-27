require 'songkick_queue/producer'

module SongkickQueue
  RSpec.describe Producer do
    describe "#publish" do
      it "should publish the message to the exchange as JSON, with the correct routing key" do
        producer = Producer.new

        exchange = double(:exchange, publish: :published)
        client = instance_double(Client, default_exchange: exchange)
        allow(producer).to receive(:client) { client }

        logger = double(:logger, info: true)
        allow(producer).to receive(:logger) { logger }

        expect(exchange).to receive(:publish)
          .with('{"example":"message","value":true}', routing_key: 'queue_name')

        expect(logger).to receive(:info).with('Published message to queue_name')

        producer.publish(:queue_name, { example: 'message', value: true })
      end

      it "should publish with a routing key using the configured queue namespace" do
        producer = Producer.new

        exchange = double(:exchange, publish: :published)
        client = instance_double(Client, default_exchange: exchange)
        allow(producer).to receive(:client) { client }

        logger = double(:logger, info: true)
        allow(producer).to receive(:logger) { logger }

        expect(exchange).to receive(:publish)
          .with('{"example":"message","value":true}', routing_key: 'test-env.queue_name')

        expect(logger).to receive(:info).with('Published message to test-env.queue_name')

        allow(producer).to receive(:config) { double(queue_namespace: 'test-env') }

        producer.publish(:queue_name, { example: 'message', value: true })
      end
    end
  end
end
