# frozen_string_literal: true

class Word
  include Mongoid::Document
  include Mongoid::Timestamps

  field :kanji, type: String
  field :romaji, type: String
  field :hiragana, type: String
  field :vietnamese_meaning, type: String
  field :difficulty_level, type: Integer, default: 1 # 1: N5, 2: N4, 3: N3, 4: N2, 5: N1
  field :example_sentence, type: String
  field :example_meaning, type: String
  field :audio_url, type: String

  # Associations
  belongs_to :lesson, optional: true
  embeds_many :kanji_strokes, cascade_callbacks: true
  has_many :user_word_progresses, dependent: :destroy

  # Indexes
  index({ lesson_id: 1 })
  index({ kanji: 1 })
  index({ difficulty_level: 1 })

  # Validations
  validates :vietnamese_meaning, presence: true
  validates :difficulty_level, presence: true, inclusion: { in: 1..5 }

  def meaning
    vietnamese_meaning
  end

  def meaning=(val)
    self.vietnamese_meaning = val
  end

  def as_json(options = {})
    {
      id: id.to_s,
      lesson_id: lesson_id&.to_s,
      kanji: kanji,
      romaji: romaji,
      hiragana: hiragana,
      vietnamese_meaning: vietnamese_meaning,
      meaning: vietnamese_meaning,
      difficulty_level: difficulty_level,
      example_sentence: example_sentence,
      example_meaning: example_meaning,
      audio_url: audio_url,
      kanji_strokes: kanji_strokes.map(&:as_json),
      created_at: created_at
    }
  end
end
