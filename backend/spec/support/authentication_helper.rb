module AuthenticationHelper
  def authenticate_user(user)
    tokens = PasetoService.generate_tokens(user)
    { "Authorization" => "Bearer #{tokens[:access_token]}" }
  end

  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    authenticate_user(user)
  end
end
