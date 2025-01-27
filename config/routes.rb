Rails.application.routes.draw do
  # indexのルートを追加する
  get 'zoom/oauth', to: 'zoom_controllers#oauth'
  get 'zoom/oauth/callback', to: 'zoom_controllers#oauth_callback'
  post 'zoom/create_meeting', to: 'zoom_controllers#create_meeting'
end
