# frozen_string_literal: true

class User < ApplicationRecord
  # Associations
  has_many :chats, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :summaries, dependent: :destroy
  has_many :messages, foreign_key: :sender_id, dependent: :destroy  # RDB版メッセージとの関連（送信者として）

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, 
                    length: { maximum: 255 },
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :encrypted_password, presence: true, length: { maximum: 255 }
  validates :is_active, inclusion: { in: [true, false] }

  # Callbacks
  before_save :downcase_email

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  # Instance Methods
  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
