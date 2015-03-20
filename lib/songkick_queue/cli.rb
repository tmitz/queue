require 'optparse'
require 'ostruct'

module SongkickQueue
  class CLI
    attr_reader :options

    def initialize(argv)
      @options = OpenStruct.new
      @options.libraries = []
      @options.consumers = []

      parse_options(argv)
    end

    def parse_options(argv)
      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: songkick_consumer [options]"

        opts.on('-r', '--require LIBRARY',
                'Path to require LIBRARY. Usually this will be a file that ',
                'requires some consumers') do |lib|
          options.libraries << lib
        end

        opts.on('-c', '--consumer CLASS_NAME',
                'Register consumer with CLASS_NAME') do |class_name|
          options.consumers << class_name
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      option_parser.parse!(argv)
    end

    def run
      options.libraries.each do |lib|
        require lib
      end

      if options.consumers.empty?
        puts "No consumers provided, exiting..."
        exit 1
      end

      consumers = options.consumers.map do |class_name|
        Object.const_get(class_name)
      end

      Worker.new(consumers).run
    end
  end
end