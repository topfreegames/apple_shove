require 'apple_shove/apns/connection'
Dir[File.join(File.dirname(__FILE__), 'apple_shove', '**', '*.rb')].each {|file| require file }

module AppleShove
  NAME = 'AppleShove'
  DEFAULTS = {
    concurrency: 25,
    reconnect_timer: 5,
    redis_key: 'apple_shove'
  }
  
  def self.redis(&block)
    raise ArgumentError, "requires a block" unless block
    redis_pool.with(&block)
  end

  def self.redis_pool
    @redis ||= AppleShove::RedisConnection.create
  end

  def self.redis=(hash)
    @redis = if hash.is_a?(ConnectionPool)
      hash
    else
      AppleShove::RedisConnection.create(hash)
    end
  end

  def self.options
    @options ||= DEFAULTS.dup
  end

  def self.options=(opts)
    @options = opts
  end
  
  def self.notify(params = {})
    notification = Notification.new params
    queue = NotificationQueue.new(self.options.fetch(:redis_key))
    queue.add(notification)
    true
  end

  def self.feedback_tokens(p12_string:, password:, sandbox: false)
    conn = APNS::FeedbackConnection.new(p12_string: p12_string, password: password, sandbox: sandbox)
    conn.device_tokens
  end

  def self.stats
    queue = NotificationQueue.new(self.options.fetch(:redis_key))
    size = queue.size
    "queue size:\t#{size}"
  end

  # raises an exception if the p12 string is invalid
  def self.try_p12(p12_pem: , password:)
    OpenSSLHelper.pkcs12_from_pem(p12_pem: p12_pem, password: password)
    true
  end
end