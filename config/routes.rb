Rails.application.routes.draw do
  # Zoom OAuth認証関連
  get 'zoom/oauth', to: 'zoom_controllers#oauth'                    # OAuth開始用
  get 'zoom/oauth/callback', to: 'zoom_controllers#oauth_callback' # OAuthのコールバック処理
  post 'zoom/create_meeting', to: 'zoom_controllers#create_zoom_meeting' # ミーティング作成用
end
