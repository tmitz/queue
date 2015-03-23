module SongkickQueue
  module Consumer
    attr_reader :delivery_info, :logger

    module ClassMethods
      def consume_from_queue(queue_name)
        @queue_name = queue_name
      end

      def queue_name
        @queue_name || fail(NotImplementedError, 'you must declare a queue name to consume from ' +
          'by calling #consume_from_queue in your consumer class. See README for more info.')
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(delivery_info, logger)
      @delivery_info = delivery_info
      @logger        = logger
    end

    def process(payload)
      fail NotImplementedError, 'you must define a #process method in your ' +
        'consumer class, see the README for more info.'
    end
  end
end
