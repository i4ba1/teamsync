module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create, :refresh]

        def create
          result = ::Auth::AuthenticateUser.call(attributes: login_params, device_info: device_info)
          user = result[:user]
          tokens = result[:tokens]

          render json: {
            data: UserSerializer.new(user).serializable_hash[:data][:attributes].merge(
              token: tokens[:access_token],
              refresh_token: tokens[:refresh_token],
              expires_in: tokens[:expires_in]
            )
          }
        end

        def destroy
          refresh_token = params[:refresh_token] || extract_refresh_token_from_header
          ::Auth::RevokeSession.call(refresh_token: refresh_token)
          head :no_content
        end

        def refresh
          tokens = ::Auth::RefreshSession.call(refresh_token: params[:refresh_token])

          render json: {
            token: tokens[:access_token],
            refresh_token: tokens[:refresh_token],
            expires_in: tokens[:expires_in]
          }
        end

        private

        def login_params
          { email: params[:email], password: params[:password] }
        end

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
