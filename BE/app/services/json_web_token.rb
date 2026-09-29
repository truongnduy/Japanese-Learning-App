# frozen_string_literal: true

class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base || ENV.fetch("JWT_SECRET", "japanese_learning_app_jwt_secret_2026")

  def self.encode(payload, exp = 7.days.from_now)
    payload_to_encode = payload.dup
    payload_to_encode[:exp] = exp.to_i
    JWT.encode(payload_to_encode, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise e
  end
end
