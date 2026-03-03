module Api
  module V1
    module Auth
      class UsersController < ApplicationController
        def show
          render json: {
            data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
          }
        end

        def update
          if current_user.update(user_params)
            render json: {
              data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
            }
          else
            render json: { 
              error: "Validation failed", 
              details: current_user.errors.full_messages 
            }, status: :unprocessable_entity
          end
        end

        private

        def user_params
          params.require(:user).permit(:first_name, :last_name, :timezone, :avatar_url)
        end
      end
    end
  end
end
