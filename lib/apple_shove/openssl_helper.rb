require 'openssl'

module AppleShove
  class OpenSSLHelper
    
    def self.pkcs12_from_pem(p12_pem: , password:)
      key  = ::OpenSSL::PKey::RSA.new(p12_pem,password)
      cert = ::OpenSSL::X509::Certificate.new p12_pem
      ::OpenSSL::PKCS12.create nil, nil, key, cert
    end

  end
end