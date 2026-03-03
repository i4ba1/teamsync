module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def disconnect
      # Any cleanup work needed when connection is closed
    end

    private

    def find_verified_user
      token = request.params[:token] || extract_token_from_header
      
      if token.blank?
        reject_unauthorized_connection
        return
      end

      payload = PasetoService.decode(token)
      
      if payload.nil?
        reject_unauthorized_connection
        return
      end

      user = User.active.find_by(id: payload["user_id"])
      
      if user.nil?
        reject_unauthorized_connection
        return
      end

      user
    rescue => e
      Rails.logger.error("WebSocket auth error: #{e.message}")
      reject_unauthorized_connection
    end

    def extract_token_from_header
      # Try to get token from cookies or query params
      request.params[:token]
    end
  end
end
