# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow local dev + your Vercel deployments (preview + prod)
    origins(
      "http://localhost:3001",
      "https://brightexam.vercel.app",
      %r{\Ahttps://brightexam-.*\.vercel\.app\z}
    )

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true,
      expose: [ "Set-Cookie" ]
  end
end
