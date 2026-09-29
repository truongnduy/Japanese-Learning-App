# frozen_string_literal: true

module Api
  module V1
    class QuizzesController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/quiz/submit
      def submit
        lesson_id = quiz_submission_params[:lesson_id]
        submitted_answers = quiz_submission_params[:answers] || []

        lesson = Lesson.find(lesson_id)
        questions = lesson.quiz_questions.to_a
        questions_map = questions.index_by { |q| q.id.to_s }

        total_questions = questions.size
        correct_count = 0
        earned_points = 0
        total_possible_points = questions.sum(&:points)
        feedback_list = []

        # Iterate through submitted answers
        submitted_answers.each do |user_ans|
          q_id = (user_ans[:question_id] || user_ans["question_id"]).to_s
          selected_val = user_ans[:selected_answer] || user_ans["selected_answer"]

          question = questions_map[q_id]

          if question
            is_correct = question.check_answer(selected_val)
            if is_correct
              correct_count += 1
              earned_points += question.points
            end

            feedback_list << {
              question_id: q_id,
              question_text: question.question_text,
              selected_answer: selected_val,
              is_correct: is_correct,
              correct_answer: question.correct_answer,
              explanation: question.explanation,
              points_awarded: is_correct ? question.points : 0
            }
          else
            feedback_list << {
              question_id: q_id,
              selected_answer: selected_val,
              is_correct: false,
              error: "Question not found in this lesson"
            }
          end
        end

        # Calculate score percentage
        score_percentage = if total_questions.positive?
                             ((correct_count.to_f / total_questions) * 100).round(1)
                           else
                             0.0
                           end

        passed = score_percentage >= 60.0

        # Save QuizAttempt record
        attempt = QuizAttempt.create!(
          user_id: current_user.id,
          lesson_id: lesson.id,
          score: score_percentage,
          earned_points: earned_points,
          total_points: total_possible_points,
          total_questions: total_questions,
          correct_count: correct_count,
          passed: passed,
          answers: feedback_list
        )

        render json: {
          status: 200,
          message: "Quiz submitted and evaluated successfully",
          quiz_attempt_id: attempt.id.to_s,
          lesson_id: lesson.id.to_s,
          lesson_title: lesson.title,
          score: score_percentage,
          earned_points: earned_points,
          total_points: total_possible_points,
          correct_count: correct_count,
          total_questions: total_questions,
          passed: passed,
          submitted_at: attempt.created_at,
          feedback: feedback_list
        }, status: :ok
      end

      # GET /api/v1/quiz/history
      def history
        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].present? ? [params[:per_page].to_i, 50].min : 15

        attempts = current_user.quiz_attempts.order_by(created_at: :desc)
        total_count = attempts.count
        paginated_attempts = attempts.skip((page - 1) * per_page).limit(per_page)

        render json: {
          status: 200,
          total_count: total_count,
          page: page,
          per_page: per_page,
          data: paginated_attempts.map(&:as_json)
        }, status: :ok
      end

      # GET /api/v1/quiz/attempts/:id
      def show_attempt
        attempt = current_user.quiz_attempts.find(params[:id])
        render json: {
          status: 200,
          data: attempt.as_json
        }, status: :ok
      end

      private

      # Strong Parameters for quiz submission
      def quiz_submission_params
        params.permit(:lesson_id, answers: [:question_id, :selected_answer])
      end
    end
  end
end
