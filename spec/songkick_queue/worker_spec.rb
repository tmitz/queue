require 'songkick_queue/worker'

module SongkickQueue
  RSpec.describe Worker do
    describe "#initialize" do
      it "should set process_name" do
        worker = Worker.new(:process_name, [:foo_consumer])

        expect(worker.process_name).to eq :process_name
      end

      it "should set consumer_classes" do
        worker = Worker.new(:process_name, [:foo_consumer, :bar_consumer])

        expect(worker.consumer_classes).to eq [:foo_consumer, :bar_consumer]
      end

      it "should convert single consumer into array of consumers" do
        worker = Worker.new(:process_name, :bar_consumer)

        expect(worker.consumer_classes).to eq [:bar_consumer]
      end

      it "should fail if no consumer passed" do
        expect { Worker.new(:process_name) }.to raise_error(ArgumentError,
          'no consumer classes given to Worker')
      end
    end

    describe "#run" do
      it "should subscribe each given consumer" do
        worker = Worker.new(:process_name, [:foo_consumer, :bar_consumer])

        allow(worker).to receive(:set_process_name)
        allow(worker).to receive(:setup_signal_catching)
        allow(worker).to receive(:stop_if_signal_caught)

        allow(worker).to receive_message_chain(:channel, :work_pool, :join)

        expect(worker).to receive(:subscribe_to_queue).with(:foo_consumer)
        expect(worker).to receive(:subscribe_to_queue).with(:bar_consumer)

        worker.run
      end
    end

    describe "#subscribe_to_queue" do
      it "should declare the queue and subscribe" do
        consumer_class = double(:consumer_class, queue_name: 'app.examples')
        worker = Worker.new(:process_name, consumer_class)

        queue = double(:queue, subscribe: :null)
        channel = double(:channel, queue: queue)

        allow(worker).to receive(:channel) { channel }
        allow(worker).to receive(:logger) { double(:logger, info: :null) }

        expect(channel).to receive(:queue).with('app.examples', durable: true,
          arguments: {'x-ha-policy' => 'all'})

        expect(queue).to receive(:subscribe)

        worker.send(:subscribe_to_queue, consumer_class)
      end
    end

    describe "#process_message" do
      it "should instantiate the consumer and call #process" do
        ::BarConsumer = Struct.new(:delivery_info, :logger)
        worker = Worker.new(:process_name, BarConsumer)

        logger = double(:logger, info: :null)
        allow(worker).to receive(:logger) { logger }

        channel = double(:channel, ack: :null)
        allow(worker).to receive(:channel) { channel }

        delivery_info = double(:delivery_info, delivery_tag: 'tag')

        consumer = double(BarConsumer, process: :null)

        expect(BarConsumer).to receive(:new)
          .with(delivery_info, logger) { consumer }

        expect(consumer).to receive(:process)
          .with({ example: 'message', value: true})

        worker.send(:process_message, BarConsumer, delivery_info, :properties,
          '{"message_id":"92c583bdc248","produced_at":"2015-03-30T15:41:55Z",' +
          '"payload":{"example":"message","value":true}}')

        expect(logger).to have_received(:info)
          .with('Processing message 92c583bdc248 via BarConsumer, produced at 2015-03-30T15:41:55Z')

        expect(channel).to have_received(:ack).with('tag', false)
      end
    end
  end
end
