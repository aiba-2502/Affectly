# frozen_string_literal: true

class Summary < ApplicationRecord
  # Enums
  enum :period, {
    session: 'session',
    daily: 'daily',
    weekly: 'weekly',
    monthly: 'monthly'
  }, validate: true

  # Associations
  belongs_to :user, optional: true
  belongs_to :chat, optional: true

  # Validations
  validates :period, presence: true
  validates :tally_start_at, presence: true
  validates :tally_end_at, presence: true
  validates :analysis_data, presence: true
  
  # Conditional validations based on period
  validates :chat_id, presence: true, if: :session_period?
  validates :user_id, presence: true, if: :user_period?
  
  validate :validate_period_associations
  validate :validate_date_range

  # Callbacks
  before_validation :set_default_analysis_data, on: :create

  # Scopes
  scope :by_period, ->(period) { where(period: period) }
  scope :sessions, -> { where(period: 'session') }
  scope :daily_summaries, -> { where(period: 'daily') }
  scope :weekly_summaries, -> { where(period: 'weekly') }
  scope :monthly_summaries, -> { where(period: 'monthly') }
  scope :in_date_range, ->(start_date, end_date) {
    where(tally_start_at: start_date..end_date)
  }
  scope :recent, -> { order(tally_start_at: :desc) }

  # Class Methods
  def self.find_or_create_for_period(user:, period:, start_at:, end_at:)
    find_or_create_by(
      user: user,
      period: period,
      tally_start_at: start_at,
      tally_end_at: end_at
    ) do |summary|
      summary.analysis_data = default_analysis_data
    end
  end

  def self.default_analysis_data
    {
      summary: '',
      insights: {},
      sentiment_overview: {},
      metrics: {}
    }
  end

  # Instance Methods
  def session_period?
    period == 'session'
  end

  def user_period?
    period.in?(['daily', 'weekly', 'monthly'])
  end

  def duration_in_days
    ((tally_end_at - tally_start_at) / 1.day).to_i
  end

  def add_insight(key, value)
    insights = analysis_data['insights'] || {}
    insights[key.to_s] = value
    update!(analysis_data: analysis_data.merge('insights' => insights))
  end

  def add_metric(key, value)
    metrics = analysis_data['metrics'] || {}
    metrics[key.to_s] = value
    update!(analysis_data: analysis_data.merge('metrics' => metrics))
  end

  def update_summary(text)
    update!(analysis_data: analysis_data.merge('summary' => text))
  end

  def sentiment_score
    analysis_data.dig('sentiment_overview', 'overall_score')
  end

  private

  def validate_period_associations
    if session_period? && user_id.present?
      errors.add(:user_id, 'はセッションサマリーでは設定できません')
    elsif user_period? && chat_id.present?
      errors.add(:chat_id, 'はユーザー期間サマリーでは設定できません')
    end
  end

  def validate_date_range
    return unless tally_start_at && tally_end_at
    
    if tally_end_at < tally_start_at
      errors.add(:tally_end_at, 'は開始日時より後である必要があります')
    end
  end

  def set_default_analysis_data
    self.analysis_data ||= self.class.default_analysis_data
  end
end
