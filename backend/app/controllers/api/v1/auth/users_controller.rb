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
          user = ::Auth::UpdateProfile.call(user: current_user, attributes: user_params)

          render json: {
            data: UserSerializer.new(user).serializable_hash[:data][:attributes]
          }
        end

        private

        def user_params
          params.require(:user).permit(:first_name, :last_name, :timezone, :avatar_url).to_h.symbolize_keys
        end
      end
    end
  end
end
