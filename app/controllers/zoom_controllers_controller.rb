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
    else
      # エラー時のレスポンス
      render json: { error: "Failed to get access token", details: result }, status: :unprocessable_entity
    end
  end

  private

  def create_zoom_meeting # create zoomURL based on student info from react
    # meeting info
    student_name = params[:student_name]
    selected_date = params[:selected_date]
    start_time = params[:start_time]
    # call zoomAPI
    uri = URI.parse("https://api.zoom.us/v2/users/me/meetings")
    # prepare access
    access_token = session[:zoom_access_token]
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"
    # setting meeting
    body = {
      topic: "#{selected_date} #{student_name}さん #{start_time} - ",
      type: 2,
      start_time: start_time,
      duration: 90,
      timezone: "Asia/Tokyo"
    }
    request.body = body.to_json
    # send request
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    result = JSON.parse(response.body)
    # responce
    if response.code.to_i == 201 && result["join_url"]
      render json: { url: result["join_url"] }
    else
      render json: { error: result["error"] }
    end
  end
end
