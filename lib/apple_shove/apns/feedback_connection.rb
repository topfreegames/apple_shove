module AppleShove
  module APNS
    class FeedbackConnection < Connection

      def initialize(p12_string:, password:, sandbox: false)
        host = "feedback.#{sandbox ? 'sandbox.' : ''}push.apple.com"
        super host: host, port: 2195, p12_string: p12_string, password: password
      end

      def device_tokens
        tokens = []
        while response = socket.read(38)
          timestamp, token_length, device_token = response.unpack('N1n1H*')
          tokens << device_token
        end

        tokens
      end

    end
  end
end