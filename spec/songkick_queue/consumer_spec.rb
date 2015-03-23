require 'songkick_queue/consumer'

module SongkickQueue
  RSpec.describe Consumer do
    describe ".from_queue" do
      it "should fail if .consume_from_queue has not been called" do
        class ExampleConsumer
          include SongkickQueue::Consumer
        end

        expect { ExampleConsumer.queue_name }.to raise_error(NotImplementedError)
      end

      it "should return the queue name set by .consume_from_queue" do
        class ExampleConsumer
          include SongkickQueue::Consumer

          consume_from_queue 'app.examples'
        end

        expect(ExampleConsumer.queue_name).to eq 'app.examples'
      end
    end

    describe "#process" do
      it "should fail if not overridden" do
        class ExampleConsumer
          include SongkickQueue::Consumer
        end

        consumer = ExampleConsumer.new(:delivery_info, nil)

        expect { consumer.process(:message) }.to raise_error(NotImplementedError)
      end
    end
  end
end
