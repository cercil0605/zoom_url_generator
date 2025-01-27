Rails.application.routes.draw do
  post '/zoom_meetings', to: 'meetings#create'
end
