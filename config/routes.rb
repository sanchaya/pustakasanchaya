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
  get '/stores' => 'stores#index', as: :stores

  # Admin routes
  namespace :admin do
    get '/login' => 'sessions#login', as: :login
    post '/login' => 'sessions#login'
    get '/logout' => 'sessions#logout', as: :logout
    post '/logout' => 'sessions#logout'
    
    get '/invite' => 'sessions#invite', as: :invite
    post '/invite' => 'sessions#invite'
    delete '/invite' => 'sessions#invite'
    get '/invite/accept/:token' => 'sessions#accept_invite', as: :accept_invite
    post '/invite/accept/:token' => 'sessions#accept_invite'
    
    get '/' => 'dashboard#index', as: :dashboard
    get '/dashboard' => 'dashboard#index'
    get '/profile' => 'dashboard#profile', as: :profile
    post '/profile' => 'dashboard#update_profile', as: :update_profile
    get '/editors' => 'dashboard#editors', as: :editors
    
    get '/books' => 'books#index', as: :books
    get '/books/search' => 'books#search', as: :books_search
    get '/books/bulk' => 'books#bulk_edit', as: :bulk_edit_books
    post '/books/bulk-preview' => 'books#bulk_preview', as: :bulk_preview_books
    post '/books/bulk-update' => 'books#bulk_update', as: :bulk_update_books
    post '/books/merge-multiple' => 'books#merge_multiple', as: :merge_multiple_books
    post '/books/:id/edit' => 'books#update', as: :update_book
    get '/books/:id/edit' => 'books#edit', as: :edit_book
    
    get '/duplicates' => 'duplicates#index', as: :duplicates
    post '/duplicates/find' => 'duplicates#find', as: :find_duplicates
    post '/duplicates/merge' => 'duplicates#merge', as: :merge_duplicates
    
    get '/corrections' => 'corrections#index', as: :corrections
    delete '/corrections' => 'corrections#destroy', as: :destroy_correction
    get '/audit-log' => 'corrections#audit_log', as: :audit_log
    
    get '/authors' => 'metadata#authors', as: :authors
    get '/authors/find-similar' => 'metadata#find_similar_authors', as: :find_similar_authors
    post '/authors/rename' => 'metadata#rename_author', as: :rename_author
    post '/authors/merge' => 'metadata#merge_authors', as: :merge_authors
    post '/authors/merge-multiple' => 'metadata#merge_multiple_authors', as: :merge_multiple_authors
    
    get '/publishers' => 'metadata#publishers', as: :publishers
    get '/publishers/find-similar' => 'metadata#find_similar_publishers', as: :find_similar_publishers
    post '/publishers/rename' => 'metadata#rename_publisher', as: :rename_publisher
    post '/publishers/merge' => 'metadata#merge_publishers', as: :merge_publishers
    post '/publishers/merge-multiple' => 'metadata#merge_multiple_publishers', as: :merge_multiple_publishers
    
    get '/categories' => 'metadata#categories', as: :categories
    get '/categories/find-similar' => 'metadata#find_similar_categories', as: :find_similar_categories
    post '/categories/rename' => 'metadata#rename_category', as: :rename_category
    post '/categories/merge' => 'metadata#merge_categories', as: :merge_categories
    post '/categories/merge-multiple' => 'metadata#merge_multiple_categories', as: :merge_multiple_categories
    
    get '/libraries' => 'metadata#libraries', as: :libraries
    get '/libraries/find-similar' => 'metadata#find_similar_libraries', as: :find_similar_libraries
    post '/libraries/rename' => 'metadata#rename_library', as: :rename_library
    post '/libraries/merge' => 'metadata#merge_libraries', as: :merge_libraries
    post '/libraries/merge-multiple' => 'metadata#merge_multiple_libraries', as: :merge_multiple_libraries
    
    get '/suggested-merges' => 'metadata#suggested_merges', as: :suggested_merges
    post '/suggested-merges/apply' => 'metadata#apply_suggestion', as: :apply_suggestion
    post '/suggested-merges/dismiss' => 'metadata#dismiss_suggestion', as: :dismiss_suggestion

    get '/stores' => 'stores#index', as: :stores
    get '/stores/new' => 'stores#new', as: :new_store
    post '/stores' => 'stores#create'
    get '/stores/:id/edit' => 'stores#edit', as: :edit_store
    patch '/stores/:id' => 'stores#update', as: :store
    put '/stores/:id' => 'stores#update'
    delete '/stores/:id' => 'stores#destroy'
    post '/stores/:id/toggle' => 'stores#toggle_active', as: :toggle_store
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
