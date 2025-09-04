class ChatMessage < ApplicationRecord
  belongs_to :user
  
  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :session_id, presence: true
  
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  
  def assistant?
    role == 'assistant'
  end
  
  def user?
    role == 'user'
  end
  
  def system?
    role == 'system'
  end
end
