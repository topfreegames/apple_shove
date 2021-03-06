require 'connection_pool'
require 'redis'
require 'uri'

module AppleShove
  class RedisConnection
    class << self

      def create(options={})
        url = options[:url] || determine_redis_provider
        if url
          options[:url] = url
        end

        # need a connection for Fetcher and Retry
        size = options[:size] || (AppleShove.options[:concurrency] + 2)
        pool_timeout = options[:pool_timeout] || 1

        log_info(options)

        ConnectionPool.new(:timeout => pool_timeout, :size => size) do
          build_client(options)
        end
      end

      private

      def build_client(options)
        namespace = options[:namespace]

        client = Redis.new client_opts(options)
        if namespace
          require 'redis/namespace'
          Redis::Namespace.new(namespace, :redis => client)
        else
          client
        end
      end

      def client_opts(options)
        opts = options.dup
        if opts[:namespace]
          opts.delete(:namespace)
        end

        if opts[:network_timeout]
          opts[:timeout] = opts[:network_timeout]
          opts.delete(:network_timeout)
        end

        opts[:driver] = opts[:driver] || 'ruby'

        opts
      end

      def log_info(options)
        # Don't log Redis AUTH password
        redacted = "REDACTED"
        scrubbed_options = options.dup
        if scrubbed_options[:url] && (uri = URI.parse(scrubbed_options[:url])) && uri.password
          uri.password = redacted
          scrubbed_options[:url] = uri.to_s
        end
        if scrubbed_options[:password]
          scrubbed_options[:password] = redacted
        end
        # if AppleShove.server?
        #   AppleShove.logger.info("Booting AppleShove #{AppleShove::VERSION} with redis options #{scrubbed_options}")
        # else
        #   AppleShove.logger.debug("#{AppleShove::NAME} client with redis options #{scrubbed_options}")
        # end
      end

      def determine_redis_provider
        ENV[ENV['REDIS_PROVIDER'] || 'REDIS_URL']
      end

    end
  end
end