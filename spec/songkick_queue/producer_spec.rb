require 'songkick_queue/producer'

module SongkickQueue
  RSpec.describe Producer do
    describe "#publish" do
      it "should publish the message to the exchange as JSON, with the correct routing key" do
        producer = Producer.new

        exchange = double(:exchange, publish: :published)
        client = instance_double(Client, default_exchange: exchange)
        allow(producer).to receive(:client) { client }

        expect(exchange).to receive(:publish)
          .with('{"example":"message","value":true}', routing_key: 'queue_name')

        producer.publish(:queue_name, { example: 'message', value: true })
      end
    end
  end
end
