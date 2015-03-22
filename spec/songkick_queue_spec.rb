require 'songkick_queue'

RSpec.describe SongkickQueue do
  describe "#configure" do
    it "should yield instance of Configuration" do
      expect { |b|
        SongkickQueue.configure(&b)
      }.to yield_with_args instance_of(SongkickQueue::Configuration)
    end
  end

  describe "#publish" do
    it "should call #publish on instance Producer" do
      producer = instance_double(SongkickQueue::Producer)
      allow(SongkickQueue::Producer).to receive(:new) { producer }

      expect(producer).to receive(:publish).with(:queue_name, :message)

      SongkickQueue.publish(:queue_name, :message)
    end
  end
end
