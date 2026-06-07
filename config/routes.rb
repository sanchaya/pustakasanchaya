Rails.application.routes.draw do
  get '/about' => 'books#about'
  get '/help' => 'books#help'
  get '/contact' => 'books#contact'
  get '/edit_wikipedia' => 'books#edit_wikipedia'
  get 'books/index'
  root 'books#index'
  get 'books/wiki_info'
  get 'books/wiki_user_info'
  get 'books/capture_user_name'
  get '/wiki' => 'books#wiki'

  get '/categories' => 'categories#index'
  get '/categories/:id' => 'categories#show'

  # Admin routes
  namespace :admin do
    get '/login' => 'sessions#login', as: :login
    post '/login' => 'sessions#login'
    get '/logout' => 'sessions#logout', as: :logout
    post '/logout' => 'sessions#logout'
    
    get '/invite' => 'sessions#invite', as: :invite
    post '/invite' => 'sessions#invite'
    get '/invite/accept/:token' => 'sessions#accept_invite', as: :accept_invite
    post '/invite/accept/:token' => 'sessions#accept_invite'
    
    get '/' => 'dashboard#index', as: :dashboard
    get '/dashboard' => 'dashboard#index'
    get '/editors' => 'dashboard#editors', as: :editors
    
    get '/books' => 'books#index', as: :books
    get '/books/search' => 'books#search', as: :books_search
    post '/books/:id/edit' => 'books#update', as: :update_book
    get '/books/:id/edit' => 'books#edit', as: :edit_book
    
    get '/duplicates' => 'duplicates#index', as: :duplicates
    post '/duplicates/find' => 'duplicates#find', as: :find_duplicates
    post '/duplicates/merge' => 'duplicates#merge', as: :merge_duplicates
    
    get '/corrections' => 'corrections#index', as: :corrections
    get '/audit-log' => 'corrections#audit_log', as: :audit_log
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
