# frozen_string_literal: true

class QuizAttempt
  include Mongoid::Document
  include Mongoid::Timestamps

  field :score, type: Float, default: 0.0 # Percentage 0.0 - 100.0
  field :earned_points, type: Integer, default: 0
  field :total_points, type: Integer, default: 0
  field :total_questions, type: Integer, default: 0
  field :correct_count, type: Integer, default: 0
  field :passed, type: Boolean, default: false
  field :answers, type: Array, default: []

  # Associations
  belongs_to :user
  belongs_to :lesson

  # Indexes
  index({ user_id: 1, lesson_id: 1 })
  index({ user_id: 1, created_at: -1 })

  def as_json(options = {})
    {
      id: id.to_s,
      user_id: user_id&.to_s,
      lesson_id: lesson_id&.to_s,
      lesson_title: lesson&.title,
      score: score,
      earned_points: earned_points,
      total_points: total_points,
      total_questions: total_questions,
      correct_count: correct_count,
      passed: passed,
      answers: answers,
      created_at: created_at
    }
  end
end
