# frozen_string_literal: true

class Lesson
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :level, type: String, default: "N5" # N5, N4, N3, N2, N1
  field :order, type: Integer, default: 1

  # Associations
  belongs_to :user, optional: true
  has_many :words, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy

  # Indexes
  index({ level: 1, order: 1 })
  index({ title: 1 })

  # Validations
  validates :title, presence: true
  validates :level, presence: true, inclusion: { in: %w[N5 N4 N3 N2 N1] }

  def total_words
    words.count
  end

  def total_questions
    quiz_questions.count
  end

  def as_json(options = {})
    {
      id: id.to_s,
      title: title,
      description: description,
      level: level,
      order: order,
      total_words: total_words,
      total_questions: total_questions,
      created_at: created_at
    }
  end
end
