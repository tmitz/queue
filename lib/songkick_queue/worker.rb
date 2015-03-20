require 'thread'

module SongkickQueue
  class Worker
    attr_reader :process_name, :consumer_classes

    def initialize(process_name, consumer_classes = [])
      @process_name = process_name
      @consumer_classes = Array(consumer_classes)

      if @consumer_classes.empty?
        fail ArgumentError, 'no consumer classes given to Worker'
      end

      @client = Client.new
    end

    def run
      set_process_name

      consumer_classes.each do |consumer_class|
        subscribe_to_queue(consumer_class)
      end

      setup_signal_catching
      stop_if_signal_caught

      channel.work_pool.join
    end

    private

    attr_reader :client

    def setup_signal_catching
      trap('INT') { @shutdown = 'INT' }
      trap('TERM') { @shutdown = 'TERM' }
    end

    def stop_if_signal_caught
      Thread.new do
        loop do
          sleep 1

          if @shutdown
            logger.info "Recevied SIG#{@shutdown}, shutting down consumers"

            @client.channel.work_pool.shutdown
          end
        end
      end
    end

    def subscribe_to_queue(consumer_class)
      queue = channel.queue(consumer_class.queue_name, durable: true,
        arguments: {'x-ha-policy' => 'all'})

      queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
        begin
          set_process_name(consumer_class)

          logger.info "Processing message via #{consumer_class}..."

          message = JSON.load(payload)

          consumer = consumer_class.new(delivery_info)
          consumer.process(message)

          channel.ack(delivery_info.delivery_tag, false)
          set_process_name
        rescue Object => exception
          logger.error(exception)
          set_process_name
        end
      end
    end

    def channel
      client.channel
    end

    def logger
      config.logger
    end

    def config
      SongkickQueue.configuration
    end

    def set_process_name(status = 'idle')
      formatted_status = String(status)
        .gsub(/([A-Z]+)/) { "_#{$1.downcase}" }
        .sub(/^_(\w)/) { $1 }

      $0 = "#{process_name}[#{formatted_status}]"
    end
  end
end
