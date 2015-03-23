require 'songkick_queue/cli'

module SongkickQueue
  RSpec.describe CLI do
    describe "#initialize" do
      it "should build an options object with defaults" do
        cli = CLI.new([])
        options = cli.options

        expect(options.libraries).to eq []
        expect(options.consumers).to eq []
        expect(options.process_name).to eq 'songkick_queue'
      end
    end

    describe "#parse_options" do
      it "should parse required libraries" do
        cli = CLI.new(%w[--require foo -r bar])
        options = cli.options

        expect(options.libraries).to eq ['foo', 'bar']
      end

      it "should parse consumers" do
        cli = CLI.new(%w[--consumer FooConsumer -c BarConsumer])
        options = cli.options

        expect(options.consumers).to eq ['FooConsumer', 'BarConsumer']
      end

      it "should parse consumers" do
        cli = CLI.new(%w[--name example_worker])
        options = cli.options

        expect(options.process_name).to eq 'example_worker'
      end
    end

    describe "#run" do
      it "should try and require given paths" do
        cli = CLI.new(%w[--require path/to/app])

        expect { cli.run }.to raise_error(LoadError, 'cannot load such file -- path/to/app')
      end

      it "should exit with useful message if no consumers given" do
        cli = CLI.new([])

        expect {
          expect(STDOUT).to receive(:puts)
            .with('No consumers provided, exiting. Run `songkick_queue --help` for more info.')

          cli.run
        }.to raise_error(SystemExit)
      end

      it "should build and run a Worker" do
        ::ExampleConsumer = Class.new

        worker = instance_double(Worker, run: :running)
        cli = CLI.new(%w[--consumer ExampleConsumer --name example_worker])

        expect(Worker).to receive(:new).with('example_worker', [ExampleConsumer]) { worker }

        cli.run
      end
    end
  end
end
