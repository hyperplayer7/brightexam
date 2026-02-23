# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow local dev and the deployed Vercel frontend origin.
    origins(
      "http://localhost:3001",
      "https://brightexam-mgkfmijsf-guesswhos-projects-ee050cfb.vercel.app"
    )

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options],
      credentials: true,
      expose: [ "Set-Cookie" ]
  end
end
