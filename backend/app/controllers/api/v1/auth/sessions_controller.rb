module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create, :refresh]

        def create
          user = User.active.find_by(email: params[:email]&.downcase)

          if user&.authenticate(params[:password])
            tokens = PasetoService.generate_tokens(user, device_info: device_info)
            
            render json: {
              data: UserSerializer.new(user).serializable_hash[:data][:attributes].merge(
                token: tokens[:access_token],
                refresh_token: tokens[:refresh_token],
                expires_in: tokens[:expires_in]
              )
            }
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end
        end

        def destroy
          refresh_token = params[:refresh_token] || extract_refresh_token_from_header
          
          if refresh_token.present?
            PasetoService.revoke_refresh_token(refresh_token)
          end
          
          head :no_content
        end

        def refresh
          refresh_token = params[:refresh_token]
          
          if refresh_token.blank?
            render json: { error: "Refresh token is required" }, status: :bad_request
            return
          end

          tokens = PasetoService.refresh_access_token(refresh_token)
          
          if tokens
            render json: {
              token: tokens[:access_token],
              refresh_token: tokens[:refresh_token],
              expires_in: tokens[:expires_in]
            }
          else
            render json: { error: "Invalid or expired refresh token" }, status: :unauthorized
          end
        end

        private

        def device_info
          request.user_agent
        end

        def extract_refresh_token_from_header
          request.headers["X-Refresh-Token"]
        end
      end
    end
  end
end
