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
  get 'books/fetch_thumbnail' => 'books#fetch_thumbnail'
  get 'books/debug_search' => 'books#debug_search'
  get '/wiki' => 'books#wiki'

  get '/categories' => 'categories#index', as: :categories
  get '/categories/letter_data' => 'categories#letter_data', as: :category_letter_data
  get '/categories/:slug' => 'categories#show', as: :category
  get '/authors' => 'authors#index', as: :authors
  get '/authors/:slug' => 'authors#show', as: :author
  get '/publishers' => 'publishers#index', as: :publishers
  get '/publishers/letter_data' => 'publishers#letter_data', as: :publisher_letter_data
  get '/publishers/:slug' => 'publishers#show', as: :publisher
  get '/libraries' => 'libraries#index', as: :libraries
  get '/libraries/:slug' => 'libraries#show', as: :library
  get '/sitemap.xml' => 'sitemaps#index', defaults: { format: :xml }
  get '/stores' => 'stores#index', as: :stores
  post '/author_suggestions' => 'author_suggestions#create'

  # Admin routes
  namespace :admin do
    # get '/tasks' => 'dashboard#tasks', as: :tasks
    get '/tasks/status' => 'dashboard#task_status', as: :task_status
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
    get '/stats' => 'dashboard#stats', as: :stats
    get '/profile' => 'dashboard#profile', as: :profile
    post '/profile' => 'dashboard#update_profile', as: :update_profile
    get '/editors' => 'dashboard#editors', as: :editors
    post '/editors/create' => 'dashboard#create_editor', as: :create_editor
    post '/editors/change-password' => 'dashboard#change_editor_password', as: :change_editor_password
    
    get '/books' => 'books#index', as: :books
    get '/books/search' => 'books#search', as: :books_search
    post '/books/merge-multiple' => 'books->merge_multiple', as: :merge_multiple_books
    get '/books/duplicates' => 'books#duplicates', as: :duplicates_books
    post '/books/merge-duplicates' => 'books#merge_duplicates', as: :merge_duplicates_books
    post '/books/:id/fetch_thumbnail' => 'books#fetch_thumbnail', as: :fetch_thumbnail_book
    post '/books/fetch_thumbnails_bulk' => 'books#fetch_thumbnails_bulk', as: :fetch_thumbnails_bulk_books
    post '/books/:id/reset_thumbnail_failed' => 'books#reset_thumbnail_failed', as: :reset_thumbnail_failed_book
    get '/books/:id/edit' => 'books#edit_form', as: :edit_book
    post '/books/:id/edit' => 'books#update_form', as: :update_book
    get '/books/:id/edit-form' => 'books#edit_form', as: :edit_form_book
    post '/books/:id/edit-form' => 'books#update_form', as: :update_form_book
    delete '/books/:id' => 'books#destroy', as: :destroy_book
    post '/books/:id/remove_contribution' => 'books#remove_contribution', as: :remove_book_contribution
    
    get '/duplicates' => 'duplicates#index', as: :duplicates
    post '/duplicates/find' => 'duplicates#find', as: :find_duplicates
    post '/duplicates/merge' => 'duplicates#merge', as: :merge_duplicates
    
    get '/corrections' => 'corrections#index', as: :corrections
    delete '/corrections' => 'corrections#destroy', as: :destroy_correction
    get '/audit-log' => 'corrections#audit_log', as: :audit_log
    
    # admin authors routes disabled – use admin/people for merges
    # get '/authors' => 'metadata#authors', as: :authors
    # get '/authors/find-similar' => 'metadata#find_similar_authors', as: :find_similar_authors
    # post '/authors/rename' => 'metadata#rename_author', as: :rename_author
    # post '/authors/merge' => 'metadata#merge_authors', as: :merge_authors
    # post '/authors/merge-multiple' => 'metadata#merge_multiple_authors', as: :merge_multiple_authors
    # get '/authors/split' => 'metadata#split_authors', as: :split_authors
    # post '/authors/split' => 'metadata#apply_split_authors', as: :apply_split_authors
    # post '/authors/dismiss_split' => 'metadata#dismiss_split', as: :dismiss_split_authors
    
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
    
    get '/meta/stores' => 'metadata#stores', as: :manage_stores
    get '/meta/stores/find-similar' => 'metadata#find_similar_stores', as: :find_similar_stores
    post '/meta/stores/rename' => 'metadata#rename_store', as: :rename_store
    post '/meta/stores/merge' => 'metadata#merge_stores', as: :merge_stores
    post '/meta/stores/merge-multiple' => 'metadata#merge_multiple_stores', as: :merge_multiple_stores
    
    get '/suggested-merges' => 'metadata#suggested_merges', as: :suggested_merges
    get '/suggested-merges/data' => 'metadata#suggestions_data', as: :suggestions_data
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
    
resources :people, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      collection do
        get :find_similar
        get :search_books
        post :rename
        post :merge
        post :merge_multiple
      end
      member do
        post :add_contribution
        post :update_contribution
        delete :remove_contribution
      end
    end
    
    resources :roles, only: [:index, :create, :update, :destroy], controller: 'roles'
    
    get '/author-suggestions' => 'metadata#author_suggestions', as: :author_suggestions
    post '/author-suggestions/:id/approve' => 'metadata#approve_suggestion', as: :approve_suggestion
    post '/author-suggestions/:id/reject' => 'metadata#reject_suggestion', as: :reject_suggestion
  end
end