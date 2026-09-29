# frozen_string_literal: true

class QuizQuestion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :question_text, type: String
  field :question_type, type: String, default: "multiple_choice"
  field :options, type: Array, default: []
  field :correct_answer, type: String
  field :explanation, type: String
  field :points, type: Integer, default: 10

  # Associations
  belongs_to :lesson

  # Indexes
  index({ lesson_id: 1 })

  # Validations
  validates :question_text, presence: true
  validates :correct_answer, presence: true

  def check_answer(user_answer)
    return false if user_answer.blank? || correct_answer.blank?

    user_ans = user_answer.to_s.strip.downcase
    corr_ans = correct_answer.to_s.strip.downcase

    # Direct match (e.g. "C" == "c", or "Người" == "người")
    return true if user_ans == corr_ans

    # If options are present, e.g. ["A. Sách", "B. Mặt trời", "C. Người", "D. Nước"]
    if options.present?
      letters = %w[a b c d e f]

      # Determine which option index corresponds to correct_answer
      target_idx = nil
      if letters.include?(corr_ans)
        target_idx = letters.index(corr_ans)
      else
        options.each_with_index do |opt, idx|
          opt_str = opt.to_s.strip.downcase
          clean_str = opt_str.sub(/^[a-z][\.\:\)\s]+\s*/, "")
          if opt_str == corr_ans || clean_str == corr_ans
            target_idx = idx
            break
          end
        end
      end

      if target_idx && target_idx < options.size
        target_letter = letters[target_idx]
        target_raw = options[target_idx].to_s.strip.downcase
        target_clean = target_raw.sub(/^[a-z][\.\:\)\s]+\s*/, "")

        # Check if user answer matches target_letter, target_raw, or target_clean
        return true if user_ans == target_letter || user_ans == target_raw || user_ans == target_clean

        # Also handle user submitting with letter prefix, e.g. "c. người"
        user_clean = user_ans.sub(/^[a-z][\.\:\)\s]+\s*/, "")
        return true if user_clean == target_clean && target_clean.present?
      end
    end

    false
  end

  # Safe payload for Flutter students doing quiz (without leaking answers)
  def safe_json
    {
      id: id.to_s,
      lesson_id: lesson_id&.to_s,
      question_text: question_text,
      question_type: question_type,
      options: options,
      points: points
    }
  end

  def as_json(options = {})
    {
      id: id.to_s,
      lesson_id: lesson_id&.to_s,
      question_text: question_text,
      question_type: question_type,
      options: options,
      correct_answer: correct_answer,
      explanation: explanation,
      points: points,
      created_at: created_at
    }
  end
end
