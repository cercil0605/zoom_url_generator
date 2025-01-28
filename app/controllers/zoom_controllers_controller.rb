class ZoomControllersController < ApplicationController
  def oauth
    # OAuth認証を開始するURLにリダイレクト
    client_id = ENV["ZOOM_CLIENT_ID"]
    redirect_uri = ENV["ZOOM_REDIRECT_URI"]
    zoom_auth_url = "https://zoom.us/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    redirect_to zoom_auth_url, allow_other_host: true
  end

  def oauth_callback
    code = params[:code]
    client_id = ENV["ZOOM_CLIENT_ID"]
    client_secret = ENV["ZOOM_CLIENT_SECRET"]
    redirect_uri = ENV["ZOOM_REDIRECT_URI"]

    # アクセストークンをリクエスト
    token_url = "https://zoom.us/oauth/token"
    uri = URI.parse(token_url)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({
                            "grant_type" => "authorization_code",
                            "code" => code,
                            "redirect_uri" => redirect_uri
                          })
    request.basic_auth(client_id, client_secret)

    # リクエスト送信
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    result = JSON.parse(response.body)

    # アクセストークン取得成功
    if response.code.to_i == 200 && result["access_token"]
      access_token = result["access_token"]
      session[:zoom_access_token] = access_token

      # Zoom APIを使ってミーティングを作成
      meeting_url = create_zoom_meeting(access_token)

      if meeting_url
        render json: { message: "Zoom authenticated successfully", meeting_url: meeting_url }, status: :ok
      else
        render json: { error: "Failed to create Zoom meeting" }, status: :unprocessable_entity
      end
    else
      # エラー時のレスポンス
      render json: { error: "Failed to get access token", details: result }, status: :unprocessable_entity
    end
  end

  private

  def create_zoom_meeting(access_token)
    # Zoomミーティング作成APIを呼び出し
    uri = URI.parse("https://api.zoom.us/v2/users/me/meetings")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"

    # ミーティングの設定
    body = {
      topic: "Sample Meeting",
      type: 2,  # Scheduled meeting
      start_time: (Time.now + 1.hour).utc.strftime('%Y-%m-%dT%H:%M:%SZ'),  # 現在時刻から1時間後
      duration: 30,
      timezone: "Asia/Tokyo"
    }
    request.body = body.to_json

    # リクエスト送信
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    result = JSON.parse(response.body)

    # 成功時にZoomミーティングのURLを返す
    response.code.to_i == 201 ? result["join_url"] : nil
  end
end
