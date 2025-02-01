# frozen_string_literal: true

class ZoomTokenMaker
  # token関連の更新or確認処理
  def check_access_token
    # sessionに保存されたtokenの情報確認、使用可or不可を確認、不可ならばregenerate関数で生成したものをsessionに保存
    # nullならばログインすらできてないのでoauthしなおし
    # return True -> トークンの確認done or regenerated
    # return False -> access tokenがnull
    access_token = session[:zoom_access_token]
    refresh_token = session[:zoom_refresh_token]
    expire_at = session[:zoom_expires_at]
    # access tokenは不正か
    return false if access_token.nil?
    # まだaccess tokenは使用できる時間
    return true if expire_at < Time.now
    # トークン再生成
    if refresh_token.nil?
      regenerate_token
    end
  end
  def regenerate_token
    # access tokenが期限切れならば新しいtokenと新しいrefresh-tokenを取得
  end
end