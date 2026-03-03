module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create]

        def create
          user = User.new(user_params)

          if user.save
            tokens = PasetoService.generate_tokens(user, device_info: device_info)
            
            render json: {
              data: UserSerializer.new(user).serializable_hash[:data][:attributes].merge(
                token: tokens[:access_token],
                refresh_token: tokens[:refresh_token],
                expires_in: tokens[:expires_in]
              )
            }, status: :created
          else
            render json: { 
              error: "Validation failed", 
              details: user.errors.full_messages 
            }, status: :unprocessable_entity
          end
        end

        private

        def user_params
          params.require(:user).permit(:email, :password, :first_name, :last_name, :timezone)
        end

        def device_info
          request.user_agent
        end
      end
    end
  end
end
