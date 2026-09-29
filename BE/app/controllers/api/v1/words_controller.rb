# frozen_string_literal: true

module Api
  module V1
    class WordsController < BaseController
      before_action :set_word, only: [:show, :study]
      before_action :authenticate_user!, only: [:study, :create]

      # GET /api/v1/words/:id
      def show
        render json: {
          status: 200,
          data: @word.as_json
        }, status: :ok
      end

      # POST /api/v1/words/:word_id/study
      def study
        # Find or initialize progress record for current_user and word
        progress = UserWordProgress.find_or_initialize_by(
          user_id: current_user.id,
          word_id: @word.id
        )

        is_new_record = progress.new_record?

        if is_new_record
          progress.studied_at = Time.current
          progress.proficiency_level = 1
          progress.review_count = 1
          progress.memorized = false
        else
          progress.studied_at = Time.current
          progress.review_count = (progress.review_count || 0) + 1
          # Increment proficiency level gradually up to level 5 (Spaced Repetition System)
          progress.proficiency_level = [progress.proficiency_level + 1, 5].min
          progress.memorized = progress.proficiency_level >= 4
        end

        if progress.save
          render json: {
            status: 200,
            message: is_new_record ? "Word marked as learned" : "Word review recorded",
            data: progress.as_json
          }, status: :ok
        else
          render json: {
            status: 422,
            error: "Unprocessable Entity",
            errors: progress.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/words
      def create
        word = Word.new(word_params)

        # Handle embedded kanji strokes if provided
        if params[:kanji_strokes].present? && params[:kanji_strokes].is_a?(Array)
          params[:kanji_strokes].each do |stroke_param|
            word.kanji_strokes.build(
              stroke_number: stroke_param[:stroke_number],
              stroke_order: stroke_param[:stroke_order],
              stroke_type: stroke_param[:stroke_type],
              svg_path: stroke_param[:svg_path],
              direction: stroke_param[:direction]
            )
          end
        end

        if word.save
          render json: {
            status: 201,
            message: "Word created successfully",
            data: word.as_json
          }, status: :created
        else
          render json: {
            status: 422,
            error: "Validation Failed",
            errors: word.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_word
        word_id = params[:word_id] || params[:id]
        @word = Word.find(word_id)
      end

      # Strong Parameters for Word creation
      def word_params
        params.require(:word).permit(
          :kanji,
          :romaji,
          :hiragana,
          :vietnamese_meaning,
          :difficulty_level,
          :example_sentence,
          :example_meaning,
          :audio_url,
          :lesson_id
        )
      end
    end
  end
end
