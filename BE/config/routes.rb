# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # 1. Authentication Endpoints
      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"
      get  "auth/me",       to: "auth#me"

      # 2. Lessons & Content Management
      resources :lessons, only: [:index, :show, :create, :update] do
        get "words", to: "lessons#words"
        get "quiz_questions", to: "lessons#quiz_questions"
      end

      # 3. Words & Study Progress Tracking
      resources :words, only: [:show, :create] do
        post "study", to: "words#study"
      end

      # 4. Quiz Submission & Feedback
      post "quiz/submit",       to: "quizzes#submit"
      get  "quiz/history",      to: "quizzes#history"
      get  "quiz/attempts/:id", to: "quizzes#show_attempt"

      # 5. User Progress Overview
      get "progress/summary", to: "progress#summary"
    end
  end
end
