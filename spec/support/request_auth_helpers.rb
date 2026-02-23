module RequestAuthHelpers
  def json_response
    body = response.body.to_s
    return {} if body.empty?

    JSON.parse(body)
  end

  def login_and_capture_cookie(email:, password:)
    post "/api/login",
      params: { email: email, password: password }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    response.headers.fetch("Set-Cookie")
  end

  def authenticated_request(method, path, cookie:, params: nil, headers: {})
    request_headers = headers.merge("Cookie" => cookie)
    if params
      request_headers["CONTENT_TYPE"] ||= "application/json"
      public_send(method, path, params: params, headers: request_headers)
    else
      public_send(method, path, headers: request_headers)
    end
  end
end
