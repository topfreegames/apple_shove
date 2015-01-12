require 'celluloid'

module AppleShove
  module APNS
    class NotifyConnection < Connection
      include Celluloid

      attr_accessor :pending_notifications
      attr_reader :name

      def initialize(p12_string:, password:, sandbox: false)
        @name = self.class.generate_name(p12_string, sandbox)
        @last_message           = nil
        @pending_notifications  = 0

        host = "gateway.#{sandbox ? 'sandbox.' : ''}push.apple.com"

        super host: host, port: 2195, p12_string: p12_string, password: password
      end

      def self.generate_name(p12, sandbox)
        Digest::SHA1.hexdigest("#{p12}#{sandbox}")
      end

      exclusive

      def connect
        super
        @last_used = Time.now
      end

      def send(notification)
        message = notification.binary_message

        begin
          if @last_used && Time.now - safe_last_used > AppleShove.options.fetch(:reconnect_timer) * 60
            Logger.info("refreshing connection", self, notification)
            reconnect
          end

          socket.write message
        rescue Exception => e
          handler = WriteExceptionHandler.new(e)
          Logger.warn(handler.message, self, notification)

          begin
            reconnect                   if handler.reconnect?
            socket.write @last_message  if handler.rewrite? && @last_message
          rescue Exception => e
            Logger.warn("failed while trying to recover from write error", self, notification)
          end

          retry                       if handler.retry?
        else
          Logger.info("delivered notification", self, notification)

          @last_message = message
          @last_used    = Time.now
        end

        @pending_notifications -= 1
      end

      def shutdown
        while @pending_notifications > 0
          Logger.info("waiting to shut down. #{@pending_notifications} job(s) remaining.", self)
          sleep 1
        end

        self.disconnect
        self.terminate
      end

    end
  end
end
