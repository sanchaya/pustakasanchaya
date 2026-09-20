# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( admin.js admin_books.js admin_people.js admin_layout.js admin_bulk_edit.js admin_duplicates.js admin_edit_form.js admin_authors.js admin_publishers.js admin_categories.js admin_libraries.js admin_suggested_merges.js google-transliteration.js )
