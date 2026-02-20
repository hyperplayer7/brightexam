Rails.application.config.session_store :cookie_store,
  key: "_brightexam_session",
  httponly: true,
  same_site: :lax
