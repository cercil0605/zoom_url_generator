require 'httparty'

class ZoomMeetingService
  BASE_URL = 'https://api.zoom.us/v2'

  def initialize
    @oauth_service = ZoomOauthService.new
  end

  def create_meeting
    token = @oauth_service.generate_access_token
    headers = {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    body = {
      topic: "サンプルミーティング",
      type: 2, # スケジュール済みミーティング
      start_time: (Time.now + 1.hour).utc.iso8601,
      duration: 30, # ミーティングの時間（分）
      timezone: "Asia/Tokyo",
      settings: {
        host_video: true,
        participant_video: true
      }
    }

    response = HTTParty.post(
      "#{BASE_URL}/users/me/meetings",
      headers: headers,
      body: body.to_json
    )

    if response.code == 201
      JSON.parse(response.body)['join_url']
    else
      raise "Zoom APIエラー: #{response.body}"
    end
  end
end
