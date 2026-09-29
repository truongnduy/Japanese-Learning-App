# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      # Error Handling
      rescue_from StandardError, with: :handle_internal_error
      rescue_from Mongoid::Errors::DocumentNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request
      rescue_from JWT::DecodeError, JWT::ExpiredSignature, with: :handle_unauthorized
      rescue_from Mongoid::Errors::Validations, with: :handle_validation_error

      attr_reader :current_user

      protected

      # Authentication Middleware
      def authenticate_user!
        header = request.headers["Authorization"]
        token = header.to_s.split(" ").last if header.present?

        if token.blank?
          render json: {
            status: 401,
            error: "Unauthorized",
            message: "Missing Authorization header with Bearer token"
          }, status: :unauthorized
          return
        end

        begin
          decoded = JsonWebToken.decode(token)
          @current_user = User.find(decoded[:user_id])
        rescue Mongoid::Errors::DocumentNotFound
          render json: {
            status: 401,
            error: "Unauthorized",
            message: "User not found or account has been deleted"
          }, status: :unauthorized
        rescue JWT::ExpiredSignature
          render json: {
            status: 401,
            error: "Unauthorized",
            message: "Token has expired. Please login again"
          }, status: :unauthorized
        rescue JWT::DecodeError => e
          render json: {
            status: 401,
            error: "Unauthorized",
            message: "Invalid token: #{e.message}"
          }, status: :unauthorized
        end
      end

      # Optional user extraction (for public endpoints that can personalize if user is logged in)
      def current_user_optional
        header = request.headers["Authorization"]
        return nil if header.blank?

        token = header.to_s.split(" ").last
        return nil if token.blank?

        decoded = JsonWebToken.decode(token)
        @current_user = User.where(id: decoded[:user_id]).first
      rescue StandardError
        nil
      end

      private

      def handle_not_found(exception)
        render json: {
          status: 404,
          error: "Not Found",
          message: "The requested resource could not be found"
        }, status: :not_found
      end

      def handle_bad_request(exception)
        render json: {
          status: 400,
          error: "Bad Request",
          message: exception.message
        }, status: :bad_request
      end

      def handle_unauthorized(exception)
        render json: {
          status: 401,
          error: "Unauthorized",
          message: exception.message
        }, status: :unauthorized
      end

      def handle_validation_error(exception)
        render json: {
          status: 422,
          error: "Unprocessable Entity",
          errors: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def handle_internal_error(exception)
        Rails.logger.error("Unhandled Exception: #{exception.message}\n#{exception.backtrace.join("\n")}")
        render json: {
          status: 500,
          error: "Internal Server Error",
          message: Rails.env.production? ? "Something went wrong" : exception.message
        }, status: :internal_server_error
      end
    end
  end
end
