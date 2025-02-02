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
    # sessionに値が保持されているか
    return false if access_token.nil || refresh_token.nil? || expire_at.nil?
    # まだaccess tokenは使用できる時間
    return true if expire_at < Time.now
    # 時間切れならば再生成、ここでエラーが発生したらfalse
    regenerate_token
  end
  def regenerate_token
    # access tokenが期限切れならば新しいtokenと新しいrefresh-tokenを取得
    token_url = "https://zoom.us/oauth/token"
    client_id = ENV["ZOOM_CLIENT_ID"]
    client_secret = ENV["ZOOM_CLIENT_SECRET"]
    refresh_token = session[:zoom_refresh_token]
    # postリクエスト送信準備
    uri = URI.parse(token_url)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({ grant_type: "refresh_token", refresh_token: refresh_token })
    request.basic_auth(client_id, client_secret)
    # リクエスト送信
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    result = JSON.parse(response.body)
    # print API result from ZOOM
    puts "(regenerate_token) ResponceCode: #{response.code}"
    puts "(regenerate_token) Response Body: #{result}"
    # success regenerate tokens
    if response.code.to_i == 200
      puts "(regenerate_token) Regenerated access token"
      session[:zoom_access_token] = result["access_token"]
      session[:zoom_refresh_token] = result["refresh_token"]
      session[:zoom_expires_at] = Time.now + result["expires_in"].to_i
      true
    end
    puts "(regenerate_token) error occurred: #{response.code}"
    false
  end
end
