require "paseto"

class PasetoService
  TOKEN_VERSION = "v2"
  PURPOSE = "public"
  ACCESS_TOKEN_LIFETIME = 15.minutes

  class << self
    def generate_keypair
      Paseto::V2::Public::SecretKey.generate
    end
    
    def secret_key
      @secret_key ||= load_or_generate_key
    end
    
    def public_key
      @public_key ||= secret_key.public_key
    end
    
    def encode(payload, expires_in: ACCESS_TOKEN_LIFETIME)
      now = Time.current
      
      token_payload = {
        "data" => payload,
        "exp" => (now + expires_in).iso8601,
        "iat" => now.iso8601,
        "jti" => SecureRandom.uuid,
        "iss" => "teamsync",
        "sub" => payload["user_id"],
        "aud" => "teamsync-api",
        "token_type" => "access"
      }
      
      secret_key.sign(token_payload.to_json, footer)
    rescue => e
      Rails.logger.error("PASETO encode error: #{e.message}")
      nil
    end
    
    def decode(token)
      return nil if token.blank?
      
      message = public_key.verify(token, footer)
      return nil if message.nil?
      
      payload = JSON.parse(message)
      
      # Check expiration
      exp = Time.parse(payload["exp"]) rescue nil
      if exp.nil? || exp < Time.current
        return nil
      end
      
      payload["data"]
    rescue Paseto::Error => e
      Rails.logger.warn("PASETO decode error: #{e.message}")
      nil
    rescue => e
      Rails.logger.error("PASETO unexpected error: #{e.message}")
      nil
    end
    
    def valid?(token)
      decode(token).present?
    end
    
    def generate_tokens(user, device_info: nil)
      access_token_payload = {
        "user_id" => user.id.to_s,
        "email" => user.email,
        "role" => user.role
      }
      
      access_token = encode(access_token_payload)
      
      # Generate refresh token
      refresh_token_str, _refresh_token = RefreshToken.generate_for(user, device_info: device_info)
      
      {
        access_token: access_token,
        refresh_token: refresh_token_str,
        expires_in: ACCESS_TOKEN_LIFETIME.to_i
      }
    end
    
    def refresh_access_token(refresh_token_str)
      refresh_token = RefreshToken.find_by_token(refresh_token_str)
      
      return nil if refresh_token.nil?
      return nil unless refresh_token.active?
      
      user = refresh_token.user
      return nil unless user&.status_active?
      
      # Rotate refresh token (security best practice)
      refresh_token.revoke!
      
      generate_tokens(user, device_info: refresh_token.device_info)
    end
    
    def revoke_refresh_token(refresh_token_str)
      refresh_token = RefreshToken.find_by_token(refresh_token_str)
      return false if refresh_token.nil?
      
      refresh_token.revoke!
      true
    end
    
    def extract_token_from_header(header)
      return nil if header.blank?
      
      scheme, token = header.split(" ", 2)
      return nil unless scheme&.downcase == "bearer"
      
      token
    end
    
    private
    
    def load_or_generate_key
      secret = ENV.fetch("PASETO_SECRET_KEY") { Rails.application.credentials.paseto_secret_key }
      
      if secret.blank?
        raise "PASETO_SECRET_KEY environment variable or paseto_secret_key credential must be set"
      end
      
      # Derive a stable 32-byte Ed25519 seed from the configured secret.
      seed = Digest::SHA256.digest(secret)
      Paseto::V2::Public::SecretKey.new(seed)
    end
    
    def footer
      { "kid" => "teamsync-#{Rails.env}" }.to_json
    end
  end
end
