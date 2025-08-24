# frozen_string_literal: true

class Chat < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :tag, optional: true
  has_many :summaries, dependent: :destroy

  # Validations
  validates :title, length: { maximum: 120 }, allow_blank: true
  validates :user, presence: true

  # Callbacks
  before_create :generate_default_title

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_tag, ->(tag_id) { where(tag_id: tag_id) }
  scope :without_tag, -> { where(tag_id: nil) }
  scope :with_tag, -> { where.not(tag_id: nil) }
  scope :by_date_range, ->(start_date, end_date) { 
    where(created_at: start_date..end_date) 
  }

  # Instance Methods
  def chat_uid
    "chat-#{id}"
  end

  # MongoDB連携用メソッド（将来的にMongoidと連携）
  def messages_count
    # TODO: MongoDBのmessages_docコレクションから取得
    # MessagesDoc.where(chat_uid: chat_uid).count
    0
  end

  def latest_message
    # TODO: MongoDBから最新メッセージを取得
    # MessagesDoc.where(chat_uid: chat_uid).order(send_at: :desc).first
    nil
  end

  def has_summary?
    summaries.where(period: 'session').exists?
  end

  def session_summary
    summaries.find_by(period: 'session')
  end

  private

  def generate_default_title
    self.title ||= "チャット #{Time.current.strftime('%Y年%m月%d日 %H:%M')}"
  end
end
