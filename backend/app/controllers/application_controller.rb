class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def authenticate_user!
    payload = extract_payload_from_token
    
    if payload.nil?
      render json: { error: "Unauthorized", message: "Invalid or missing authentication token" }, status: :unauthorized
      return
    end
    
    @current_user = User.active.find_by(id: payload["user_id"])
    
    if @current_user.nil?
      render json: { error: "Unauthorized", message: "User not found or inactive" }, status: :unauthorized
    end
  rescue => e
    Rails.logger.error("Authentication error: #{e.message}")
    render json: { error: "Unauthorized", message: "Authentication failed" }, status: :unauthorized
  end

  def current_user
    @current_user
  end

  def extract_payload_from_token
    auth_header = request.headers["Authorization"]
    token = PasetoService.extract_token_from_header(auth_header)
    PasetoService.decode(token)
  end

  def not_found(exception)
    render json: { error: "Not Found", message: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { 
      error: "Unprocessable Entity", 
      message: exception.message,
      details: exception.record&.errors&.full_messages 
    }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: { error: "Bad Request", message: exception.message }, status: :bad_request
  end

  def render_json(data, status: :ok, serializer: nil, options: {})
    if serializer.present?
      render json: serializer.new(data, options).serializable_hash, status: status
    else
      render json: data, status: status
    end
  end

  def render_error(message, status: :unprocessable_entity, details: nil)
    response = { error: message }
    response[:details] = details if details.present?
    render json: response, status: status
  end

  def pagination_meta(object)
    {
      current_page: object.current_page,
      next_page: object.next_page,
      prev_page: object.prev_page,
      total_pages: object.total_pages,
      total_count: object.total_count
    }
  end
end
