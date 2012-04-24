Dealmap::Application.routes.draw do

  resources :images

  #ActiveAdmin.routes(self)

  #devise_for :admin_users, ActiveAdmin::Devise.config
  
  resources :tags

  get "sessions/new"
  match 'contact' => 'contact#new', :as => 'contact', :via => :get
  match 'contact' => 'contact#create', :as => 'contact', :via => :post
  
  match '/about',   :to => 'pages#about'
  match '/privacy',    :to => 'pages#privacy'
  
#  post "imports/csv_import"
#
#  get "imports/csv_import"
  get "deals/import"
  match '/deals/upload' => 'deals#upload'
  resources :deal_locations
  
  resources :deal_locations do 
    member do
      post 'new'
    end
  end
  resources :searches

  resources :sale_details

  resources :sales

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]

  match '/signup',  :to => 'users#new'
  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  
  root :to => 'deals#index'

  resources :deals
  
  resources :deals do
    member do
      post 'print'
    end
  end
  resources :user_types

  resources :categories
  
  match '/sales/new/deals/:deal_id' => 'sales#new'
  
  match '/deals/:deal_id/print' => 'deals#print'
  
  match '/get_deals_within_bounds' => 'deals#get_deals_within_bounds'
  match '/get_deal' => 'deals#get_deal'
  match '/get_deals_for_view' => 'deals#get_deals_for_view'
    
  get 'scrape/scrape_schedule'
  get 'scrape/scrape_site'
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
