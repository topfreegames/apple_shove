require 'apple_shove'
require './spec/notification_helper'

describe AppleShove::Notification do
  include NotificationHelper
  
  before do
    @n = generate_notification
  end

  it "converts to and from json" do
    json = @n.to_json
    expect(json).to be_an_instance_of(String)
    n2 = AppleShove::Notification.parse(json)
    expect(@n.to_json).to eq(n2.to_json)
  end

  it "creates a binary message for apns" do
    m = @n.binary_message

    expect(m).to be_an_instance_of(String)
    expect(m.length).to be > 0
  end

end