class ZoomControllersController < ApplicationController
  def oauth
    # OAuth認証を開始するURLにリダイレクト
    client_id = ENV["ZOOM_CLIENT_ID"]
    redirect_uri = ENV["ZOOM_REDIRECT_URI"]
    zoom_auth_url = "https://zoom.us/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    redirect_to zoom_auth_url, allow_other_host: true
  end

  def oauth_callback
    begin
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

      puts "Response Code: #{response.code}"
      puts "Response Body: #{result}"

      # アクセストークン取得成功
      if response.code.to_i == 200 && result["access_token"]
        access_token = result["access_token"]
        session[:zoom_access_token] = access_token
        # redirect front page for setup meeting
        redirect_to "http://localhost:3000/dashboard"
        puts "(/oauth/callback): #{access_token}"
      else
        render json: { error: "Failed to get access token", details: result }, status: :unprocessable_entity
      end
    rescue => e
      puts "Error in oauth_callback: #{e.message}"
      render json: { error: "Something went wrong", details: e.message }, status: :internal_server_error
    end
  end

  def create_zoom_meeting # create zoomURL based on student info from React
    # meeting info
    student_name = params[:student_name]
    selected_date = params[:selected_date]
    start_time = params[:start_time]
    timezone = "Asia/Tokyo"
    # call zoomAPI
    uri = URI.parse("https://api.zoom.us/v2/users/me/meetings")
    # prepare access token
    access_token = session[:zoom_access_token]
    # for unauthorized user
    if access_token == nil
      render json: { status: "error", message: "Zoomアカウントを認証してください" }, status: :unauthorized
      return
    end
    # check token
    puts "(/create) #{access_token}"
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"
    # setting meeting
    body = {
      topic: "#{selected_date} #{student_name}さん #{start_time} - ",
      type: 2,
      start_time: Time.zone.parse("#{selected_date} #{start_time}").in_time_zone(timezone).iso8601, # set time based on iso8601, Asia/Tokyo timezone
      duration: 90,
      timezone: timezone
    }
    request.body = body.to_json
    # send request
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    result = JSON.parse(response.body)
    # print API result from ZOOM
    puts "ResponceCode #{response.code}"
    puts "Response Body: #{result}"
    # generate template
    if response.code.to_i == 201 && result["join_url"]
      # print generated meeting time
      puts "Meeting Time: #{Time.zone.parse(result["start_time"]).strftime("%Y年%m月%d日 %H:%M")}"
      # template message val
      student_name = params[:student_name] || "生徒"
      message_topic = result["topic"]
      message_start_time = Time.zone.parse(result["start_time"]).strftime("%Y年%m月%d日 %H:%M")
      join_url = result["join_url"]
      # template message
      message = "#{student_name}さん、本日は授業お疲れ様でした。次回のURLです。\n"
      message += "トピック：#{message_topic}\n"
      message += "時刻：#{message_start_time}\n"
      message += "URL：#{join_url}"

      # return status and message to React(success)
      render json: { status: "success", message: message }, status: :created
    else
      # return status and message to React(failed)
      render json: { status: "error", message: result["message"] }, status: :unauthorized
    end
  end
end
