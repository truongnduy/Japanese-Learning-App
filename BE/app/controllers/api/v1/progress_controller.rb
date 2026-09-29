# frozen_string_literal: true

module Api
  module V1
    class ProgressController < BaseController
      before_action :authenticate_user!

      # GET /api/v1/progress/summary
      def summary
        progresses = current_user.user_word_progresses
        attempts = current_user.quiz_attempts

        total_studied_words = progresses.count
        memorized_words = progresses.where(memorized: true).count

        # Recent activities
        recent_studied = progresses.order_by(studied_at: :desc).limit(10).map(&:as_json)
        recent_quizzes = attempts.order_by(created_at: :desc).limit(5).map(&:as_json)

        quiz_count = attempts.count
        avg_score = quiz_count.positive? ? (attempts.avg(:score) || 0).round(1) : 0.0
        passed_quizzes = attempts.where(passed: true).count

        render json: {
          status: 200,
          data: {
            study_stats: {
              total_studied_words: total_studied_words,
              memorized_words: memorized_words,
              learning_in_progress: total_studied_words - memorized_words
            },
            quiz_stats: {
              total_quizzes_taken: quiz_count,
              average_score: avg_score,
              passed_quizzes_count: passed_quizzes,
              pass_rate: quiz_count.positive? ? ((passed_quizzes.to_f / quiz_count) * 100).round(1) : 0.0
            },
            recent_studied_words: recent_studied,
            recent_quiz_attempts: recent_quizzes
          }
        }, status: :ok
      end
    end
  end
end
