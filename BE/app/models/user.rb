# frozen_string_literal: true

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String
  field :role, type: String, default: "student"

  has_secure_password

  # Associations
  has_many :lessons, dependent: :nullify
  has_many :quiz_attempts, dependent: :destroy
  has_many :user_word_progresses, dependent: :destroy

  # Indexes
  index({ email: 1 }, { unique: true })

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  before_save :downcase_email

  def as_json(options = {})
    {
      id: id.to_s,
      name: name,
      email: email,
      role: role,
      created_at: created_at
    }
  end

  private

  def downcase_email
    self.email = email.downcase.strip if email.present?
  end
end
