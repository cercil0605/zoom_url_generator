require 'httparty'

class ZoomOauthService
  BASE_URL = 'https://zoom.us/oauth'

  def initialize
    @client_id = ENV['ZOOM_CLIENT_ID']
    @client_secret = ENV['ZOOM_CLIENT_SECRET']
    @account_id = ENV['ZOOM_ACCOUNT_ID']
  end

  def generate_access_token
    response = HTTParty.post(
      "#{BASE_URL}/token",
      body: {
        grant_type: 'account_credentials',
        account_id: @account_id
      },
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    )

    if response.code == 200
      JSON.parse(response.body)['access_token']
    else
      raise "Failed to get access token: #{response.body}"
    end
  end
end
