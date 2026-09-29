# frozen_string_literal: true

module Api
  module V1
    class LessonsController < BaseController
      before_action :set_lesson, only: [:show, :words, :quiz_questions]
      before_action :authenticate_user!, only: [:create, :update, :destroy]

      # GET /api/v1/lessons
      # Query params: level (e.g. N5), query (search by title), page, per_page
      def index
        lessons = Lesson.all

        if params[:level].present?
          lessons = lessons.where(level: filter_params[:level].to_s.upcase)
        end

        if params[:query].present?
          search_term = filter_params[:query].to_s.strip
          lessons = lessons.where(title: /#{Regexp.escape(search_term)}/i)
        end

        lessons = lessons.order_by(order: :asc, created_at: :asc)

        # Pagination
        page = [filter_params[:page].to_i, 1].max
        per_page = filter_params[:per_page].present? ? [filter_params[:per_page].to_i, 100].min : 20
        total_count = lessons.count
        paginated_lessons = lessons.skip((page - 1) * per_page).limit(per_page)

        render json: {
          status: 200,
          total_count: total_count,
          page: page,
          per_page: per_page,
          data: paginated_lessons.map(&:as_json)
        }, status: :ok
      end

      # GET /api/v1/lessons/:id
      def show
        render json: {
          status: 200,
          data: @lesson.as_json.merge(
            words_count: @lesson.total_words,
            quiz_questions_count: @lesson.total_questions
          )
        }, status: :ok
      end

      # GET /api/v1/lessons/:lesson_id/words
      def words
        words_query = @lesson.words.order_by(created_at: :asc)

        # Check if user is logged in to attach study progress
        current_user_optional
        studied_word_ids = if @current_user
                             @current_user.user_word_progresses.pluck(:word_id).map(&:to_s)
                           else
                             []
                           end

        formatted_words = words_query.map do |w|
          word_data = w.as_json
          word_data[:is_studied] = studied_word_ids.include?(w.id.to_s)
          word_data
        end

        render json: {
          status: 200,
          lesson_id: @lesson.id.to_s,
          lesson_title: @lesson.title,
          total_words: formatted_words.size,
          data: formatted_words
        }, status: :ok
      end

      # GET /api/v1/lessons/:lesson_id/quiz_questions
      def quiz_questions
        questions = @lesson.quiz_questions.order_by(created_at: :asc)

        render json: {
          status: 200,
          lesson_id: @lesson.id.to_s,
          lesson_title: @lesson.title,
          total_questions: questions.count,
          data: questions.map(&:safe_json)
        }, status: :ok
      end

      # POST /api/v1/lessons
      def create
        lesson = Lesson.new(lesson_create_params)
        lesson.user = current_user

        if lesson.save
          render json: {
            status: 201,
            message: "Lesson created successfully",
            data: lesson.as_json
          }, status: :created
        else
          render json: {
            status: 422,
            error: "Validation Failed",
            errors: lesson.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/lessons/:id
      def update
        set_lesson
        if @lesson.update(lesson_update_params)
          render json: {
            status: 200,
            message: "Lesson updated successfully",
            data: @lesson.as_json
          }, status: :ok
        else
          render json: {
            status: 422,
            error: "Validation Failed",
            errors: @lesson.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_lesson
        lesson_id = params[:lesson_id] || params[:id]
        @lesson = Lesson.find(lesson_id)
      end

      # Strong Parameters for filter and pagination
      def filter_params
        params.permit(:level, :query, :page, :per_page)
      end

      # Strong Parameters for lesson creation
      def lesson_create_params
        params.require(:lesson).permit(:title, :description, :level, :order)
      end

      # Strong Parameters for lesson update
      def lesson_update_params
        params.require(:lesson).permit(:title, :description, :level, :order)
      end
    end
  end
end
