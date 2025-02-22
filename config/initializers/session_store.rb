# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, 
  key: '_zoom_url_generator_session', 
  expire_after: 1.hour,  # 必要に応じてセッションの有効期限を設定
  domain: :all,         # サブドメインでもクッキーを共有する場合
  same_site: :lax,   # こいつが原因だった、許さない
  secure: Rails.env.production?  # 本番環境でのみセキュアなクッキーを使用