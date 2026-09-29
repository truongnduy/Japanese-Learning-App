# frozen_string_literal: true

class UserWordProgress
  include Mongoid::Document
  include Mongoid::Timestamps

  field :studied_at, type: Time, default: -> { Time.current }
  field :proficiency_level, type: Integer, default: 1
  field :review_count, type: Integer, default: 1
  field :memorized, type: Boolean, default: false

  # Associations
  belongs_to :user
  belongs_to :word

  # Indexes
  index({ user_id: 1, word_id: 1 }, { unique: true })
  index({ user_id: 1, studied_at: -1 })

  def as_json(options = {})
    {
      id: id.to_s,
      user_id: user_id&.to_s,
      word_id: word_id&.to_s,
      word_kanji: word&.kanji,
      word_meaning: word&.vietnamese_meaning,
      studied_at: studied_at,
      proficiency_level: proficiency_level,
      review_count: review_count,
      memorized: memorized,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
