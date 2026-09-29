# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      wrap_parameters false

      before_action :authenticate_user!, only: [:me]

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)

        if user.save
          token = JsonWebToken.encode(user_id: user.id.to_s)
          render json: {
            status: 201,
            message: "User registered successfully",
            token: token,
            user: user.as_json
          }, status: :created
        else
          render json: {
            status: 422,
            error: "Validation Failed",
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        email = credentials_params[:email].to_s.downcase.strip
        password = credentials_params[:password]

        if email.blank? || password.blank?
          render json: {
            status: 400,
            error: "Bad Request",
            message: "Email and password are required"
          }, status: :bad_request
          return
        end

        user = User.where(email: email).first

        if user&.authenticate(password)
          token = JsonWebToken.encode(user_id: user.id.to_s)
          render json: {
            status: 200,
            message: "Login successful",
            token: token,
            user: user.as_json
          }, status: :ok
        else
          render json: {
            status: 401,
            error: "Unauthorized",
            message: "Invalid email or password"
          }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        studied_count = current_user.user_word_progresses.count
        quiz_attempts_count = current_user.quiz_attempts.count
        avg_score = quiz_attempts_count.positive? ? (current_user.quiz_attempts.avg(:score) || 0).round(1) : 0

        render json: {
          status: 200,
          user: current_user.as_json,
          statistics: {
            words_studied_count: studied_count,
            quizzes_taken_count: quiz_attempts_count,
            average_quiz_score: avg_score
          }
        }, status: :ok
      end

      private

      # Strong Parameters for registration
      def user_params
        if params[:user].present?
          params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
        else
          params.permit(:name, :email, :password, :password_confirmation, :role)
        end
      end

      # Strong Parameters for login (supports flat, nested under :user, or nested under :auth)
      def credentials_params
        permitted = params.permit(
          :email,
          :password,
          user: [:email, :password],
          auth: [:email, :password, user: [:email, :password]]
        )

        email = permitted[:email] ||
                permitted.dig(:user, :email) ||
                permitted.dig(:auth, :email) ||
                permitted.dig(:auth, :user, :email)

        password = permitted[:password] ||
                   permitted.dig(:user, :password) ||
                   permitted.dig(:auth, :password) ||
                   permitted.dig(:auth, :user, :password)

        { email: email, password: password }
      end
    end
  end
end
