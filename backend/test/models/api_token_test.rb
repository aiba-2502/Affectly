require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      name: "Test User"
    )
  end

  # トークンペア生成のテスト
  test "should generate token pair with access and refresh tokens" do
    tokens = ApiToken.generate_token_pair(@user)

    assert_not_nil tokens[:access_token]
    assert_not_nil tokens[:refresh_token]

    assert_equal "access", tokens[:access_token].token_kind
    assert_equal "refresh", tokens[:refresh_token].token_kind

    # アクセストークンは2時間後に期限切れ
    assert_in_delta 2.hours.from_now.to_i, tokens[:access_token].expires_at.to_i, 5

    # リフレッシュトークンは7日後に期限切れ
    assert_in_delta 7.days.from_now.to_i, tokens[:refresh_token].expires_at.to_i, 5

    #  token_family_idが設定されている
    assert_not_nil tokens[:refresh_token]. token_family_id
  end

  # トークン検証のテスト
  test "should validate token correctly" do
    token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.from_now
    )

    assert token.token_valid?

    # 期限切れトークンは無効
    expired_token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.ago
    )

    assert_not expired_token.token_valid?

    # 無効化されたトークンは無効
    revoked_token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.from_now,
      revoked_at: Time.current
    )

    assert_not revoked_token.token_valid?
  end

  # トークンチェーン無効化のテスト
  test "should revoke entire token chain" do
     token_family_id = SecureRandom.uuid

    token1 = ApiToken.create!(
      user: @user,
      token_kind: "refresh",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 7.days.from_now,
       token_family_id:  token_family_id
    )

    token2 = ApiToken.create!(
      user: @user,
      token_kind: "refresh",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 7.days.from_now,
       token_family_id:  token_family_id
    )

    # チェーン全体を無効化
    token1.revoke_chain!

    token1.reload
    token2.reload

    assert_not_nil token1.revoked_at
    assert_not_nil token2.revoked_at
  end

  # スコープのテスト
  test "should filter tokens by scope" do
    # アクティブなトークン
    active_token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.from_now
    )

    # 期限切れトークン
    expired_token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.ago
    )

    # 無効化されたトークン
    revoked_token = ApiToken.create!(
      user: @user,
      token_kind: "access",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.from_now,
      revoked_at: Time.current
    )

    # リフレッシュトークン
    refresh_token = ApiToken.create!(
      user: @user,
      token_kind: "refresh",
      encrypted_token: SecureRandom.urlsafe_base64(32),
      expires_at: 7.days.from_now
    )

    # activeスコープのテスト
    active_tokens = ApiToken.active
    assert_includes active_tokens, active_token
    assert_includes active_tokens, refresh_token
    assert_not_includes active_tokens, expired_token
    assert_not_includes active_tokens, revoked_token

    # access_tokensスコープのテスト
    access_tokens = ApiToken.access_tokens
    assert_includes access_tokens, active_token
    assert_includes access_tokens, expired_token
    assert_includes access_tokens, revoked_token
    assert_not_includes access_tokens, refresh_token

    # refresh_tokensスコープのテスト
    refresh_tokens = ApiToken.refresh_tokens
    assert_includes refresh_tokens, refresh_token
    assert_not_includes refresh_tokens, active_token
  end

  # クリーンアップのテスト
  test "should cleanup old tokens keeping only recent ones" do
    # 6つのリフレッシュトークンを作成
    6.times do |i|
      ApiToken.create!(
        user: @user,
        token_kind: "refresh",
        encrypted_token: SecureRandom.urlsafe_base64(32),
        expires_at: 7.days.from_now,
        created_at: i.hours.ago
      )
    end

    assert_equal 6, ApiToken.where(user: @user, token_kind: "refresh").count

    # 最新5つのみ保持
    ApiToken.cleanup_old_tokens(@user.id, keep_count: 5)

    active_refresh_tokens = ApiToken.where(user: @user, token_kind: "refresh", revoked_at: nil)
    assert_equal 5, active_refresh_tokens.count

    # 最も古いトークンが無効化されていることを確認
    oldest_token = ApiToken.where(user: @user, token_kind: "refresh").order(created_at: :asc).first
    assert_not_nil oldest_token.revoked_at
  end

  # セキュアトークン生成のテスト
  test "should generate secure token" do
    token1 = ApiToken.generate_secure_token
    token2 = ApiToken.generate_secure_token

    # トークンは毎回異なる
    assert_not_equal token1, token2

    # 適切な長さ
    assert_equal 43, token1.length # Base64エンコードされた32バイト
  end
end
