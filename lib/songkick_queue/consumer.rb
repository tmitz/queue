module SongkickQueue
  module Consumer
    attr_reader :delivery_info, :logger

    module ClassMethods
      # Define the name of the queue this consumer with process messages from
      #
      # @param queue_name [String]
      def consume_from_queue(queue_name)
        @queue_name = queue_name
      end

      # Return the quene name set by #consume_from_queue
      #
      # @raise [NotImplementedError] if queue name was not already defined
      def queue_name
        @queue_name or fail(NotImplementedError, 'you must declare a queue name to consume from ' +
          'by calling #consume_from_queue in your consumer class. See README for more info.')
      end

      def config
        SongkickQueue.configuration
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # @param delivery_info [Bunny::DeliveryInfo#delivery_tag] to use for
    #   acknowledgement and requeues, rejects etc...
    # @param logger [Logger] to expose to the client consumer for logging
    def initialize(delivery_info, logger)
      @delivery_info = delivery_info
      @logger        = logger
    end

    # Placeholder method to ensure each client consumer defines their own
    # process message
    #
    # @param message [Object] to process
    # @raise [NotImplementedError]
    def process(message)
      fail NotImplementedError, 'you must define a #process method in your ' +
        'consumer class, see the README for more info.'
    end
  end
end
