require 'json'
require 'redis'

module AppleShove
  class NotificationQueue
    
    def initialize(key)
      @key = key
    end
    
    def add(notification)
      AppleShove.redis { |redis| redis.rpush @key, notification.to_json }
    end
    
    def get
      element = AppleShove.redis { |redis| redis.lpop @key }
      element ? Notification.parse(element) : nil
    end

    def size
      AppleShove.redis { |redis| redis.llen @key }
    end   

  end
end