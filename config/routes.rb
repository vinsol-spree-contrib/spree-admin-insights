Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :insights
  end
end
