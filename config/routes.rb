Spree::Core::Engine.routes.draw do
  namespace :admin do
    get 'insights/download', to: 'insights#download'
    resources :insights
  end
end
