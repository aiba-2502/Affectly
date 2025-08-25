class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  # MongoDB Collection name
  store_in collection: "messages_doc"

  # Fields based on DB_GUID.md specification
  field :chat_uid, type: String
  field :sender_id, type: Integer
  field :content, type: String
  field :llm_metadata, type: Hash, default: {}
  field :emotion_score, type: Float
  field :emotion_keywords, type: Array, default: []
  field :send_at, type: Time

  # Validations
  validates :chat_uid, presence: true
  validates :sender_id, presence: true
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :send_at, presence: true
  validates :emotion_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  
  # Custom validation for emotion_keywords array size
  validate :emotion_keywords_size_limit

  # Indexes for performance
  index({ chat_uid: 1, send_at: -1 })
  index({ sender_id: 1 })
  index({ send_at: -1 })

  # Scopes
  scope :by_chat, ->(chat_uid) { where(chat_uid: chat_uid) }
  scope :by_sender, ->(sender_id) { where(sender_id: sender_id) }
  scope :recent_first, -> { order(send_at: :desc) }
  scope :chronological, -> { order(send_at: :asc) }

  # Class methods
  def self.for_chat(chat_id)
    chat_uid = "chat-#{chat_id}"
    by_chat(chat_uid).chronological
  end

  # Instance methods
  def chat_id
    chat_uid&.gsub(/^chat-/, '')&.to_i
  end

  def user_message?
    sender_id.present? && sender_id > 0
  end

  def system_message?
    !user_message?
  end

  # Before validation callback to ensure send_at is set
  before_validation :set_send_at

  private

  def emotion_keywords_size_limit
    if emotion_keywords.present? && emotion_keywords.size > 10
      errors.add(:emotion_keywords, "は10個まで登録可能です")
    end
  end

  def set_send_at
    self.send_at ||= Time.current
  end
end