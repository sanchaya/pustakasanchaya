# Pustaka Sanchaya (ಪುಸ್ತಕ ಸಂಚಯ)

Kannada book search portal — a frontend Rails client that aggregates books from digital libraries (Internet Archive JaiGyan, ServantsOfKnowledge, Osmania, DLI, and others) and provides a searchable catalog with category browsing, book thumbnails, and a Wikipedia article creation workflow.

**Production:** https://pustaka.sanchaya.net  
**Backend API:** https://samooha.sanchaya.net  
**Ruby:** 2.4.6 | **Rails:** 4.2.11.1 | **Server:** Phusion Passenger + nginx

---

## Architecture

This is a **model-less Rails application** — no database, no ActiveRecord. The `Book` model is a Plain Old Ruby Object with class methods that use HTTParty to communicate with the backend API at `samooha.sanchaya.net`. All book data, categories, and wiki book information come from that API.

```
User → nginx (SSL termination) → Passenger → Rails app → HTTParty → samooha.sanchaya.net (backend API)
                                                                   ↓
                                                              Internet Archive / Wikipedia
```

The backend API (`samooha.sanchaya.net`) is a separate Rails app serving as a data aggregation layer. This frontend app only queries it and renders results.

### Data Flow

- **Books** — Searched via `GET /search.json?search=<query>` on the backend API. Results include name, author, publisher, library, year, book_link, archive_url, metadata (wikimedia/wikisource URLs), and source_identifier for Internet Archive items.
- **Categories** — Fetched from `GET /categories`. Returns an array of `{id, kn}` objects (Kannada category names).
- **Category Books** — Fetched from `GET /categories/:id`. Returns books for that category.
- **Wiki Book** — Fetched from `GET /wiki_books`. Returns a random book from the catalog with its metadata for Wikipedia article creation.
- **Stats** — Computed locally from cached JSON files (`db/*.json`) via the `stats` helper.

### Cached Data

Two large JSON files cache Internet Archive collection data for offline search:

| File | Records | Source |
|------|---------|--------|
| `db/jai_gyan_books.json` | ~18,857 | Internet Archive JaiGyan collection (`kan` language) |
| `db/servants_of_knowledge_books.json` | ~23,402 | Internet Archive ServantsOfKnowledge collection |
| `db/stats.json` | computed | Aggregated counts (42,259 books, 18 libraries, 10,870 authors, 5,261 publishers) |

---

## Setup

### Prerequisites

- Ruby 2.4.6 (via RVM)
- Bundler
- nginx + Phusion Passenger (for production)

### Development

```bash
git clone <repo> pustaka
cd pustaka
bundle install
rails server
```

In development, the app queries `http://localhost:3001` as the backend API (configured in `app/models/book.rb`).

### Production Deployment

The app is deployed via **Capistrano** and served by **Phusion Passenger** behind **nginx** with SSL.

**Restart after changes:**
```bash
cd /home/pustaka/rails_apps/prod/current
bundle exec rake assets:precompile RAILS_ENV=production
touch tmp/restart.txt
```

**Nginx vhost:** Config at `/etc/nginx/sites-enabled/pustaka.sanchaya.net`  
**Ruby env:** `/usr/local/rvm/wrappers/ruby-2.4.6/ruby`  
**App root:** `/home/pustaka/rails_apps/prod/current/public`

---

## Routes

| Path | Controller#Action | Description |
|------|-------------------|-------------|
| `/` | `books#index` | Homepage — search form + stats counters |
| `/categories` | `categories#index` | Category browser with search filter |
| `/categories/:id` | `categories#show` | Books in a category (paginated) |
| `/wiki` | `books#wiki` | Wikipedia article creation workflow |
| `/about` | `books#about` | About page |
| `/help` | `books#help` | Help page |
| `/contact` | `books#contact` | Contact page |
| `/edit_wikipedia` | `books#edit_wikipedia` | Static info about wiki editing |
| `/books/index` | `books#index` | Search action (also handles search params) |
| `/books/wiki_info` | `books#wiki_info` | Log wiki view events |
| `/books/wiki_user_info` | `books#wiki_user_info` | Confirm wiki user & article creation |
| `/books/capture_user_name` | `books#capture_user_name` | Store wiki username in session |

---

## Key Components

### Models (`app/models/book.rb`)

| Method | Description |
|--------|-------------|
| `Book.search(query)` | Searches the backend API for books |
| `Book.categories` | Returns all categories from the backend API |
| `Book.category_books(id)` | Returns books for a specific category |
| `Book.wiki_search` | Returns a random book with wiki metadata |
| `Book.capture_wiki_user(...)` | Logs wiki user activity to backend |
| `Book.search_ia(query)` | Directly queries Internet Archive search API |
| `Book.ia_jai_gyan_books` | Queries IA JaiGyan collection directly |
| `Book.ia_book_details(identifier)` | Fetches IA book metadata by identifier |
| `Book.search_all_cached(query)` | Offline search across local JSON caches |

### Controllers

- **`BooksController`** — Search, wiki workflow, static pages
- **`CategoriesController`** — Category listing and browsing

### Helpers

| Helper | Description |
|--------|-------------|
| `stats` | Reads computed counts from `db/stats.json` |
| `broken_link?(url)` | Checks if a URL belongs to defunct domains (DLI, OUDL, Osmania) |
| `book_thumbnail_url(book)` | Constructs an IA thumbnail URL from `archive_url` |
| `book_thumbnail_tag(book)` | Renders an `<img>` tag with IA thumbnail or grey logo fallback |
| `wikimedia_url(metadata)` | Extracts Wikimedia Commons URL from metadata text |
| `wikisource_url(metadata)` | Extracts Wikisource URL from metadata text |
| `clean_link(link)` | Converts underscores to dots in IA-style URLs |

### Views

- **Homepage** (`books/index.html.erb`) — Search bar + stats counters
- **Categories** (`categories/index.html.erb`) — Card grid with client-side search filter
- **Category Show** (`categories/show.html.erb`) — Book listing for a category
- **Search Results** (`books/_book_lists.html.erb`) — Table with book details, thumbnails, and links
- **Wiki Page** (`books/wiki.html.erb`) — Three-step workflow for Wikipedia article creation

---

## Book Thumbnails

Search results show a 48×64px thumbnail column:

- **Internet Archive books** — Thumbnail loaded from `https://archive.org/services/img/<identifier>`
- **Fallback** — Grey (`opacity: 0.3`, `grayscale(1)`) Sanchaya logo
- **On error** — Falls back to the same grey logo via JavaScript `onerror` handler

---

## Wikipedia Integration

The `/wiki` page provides a three-step workflow for creating book articles on Kannada Wikipedia:

1. **Step 1** — Enter your Wikipedia username (validated, stored in session)
2. **Step 2** — Copy wiki template syntax via ZeroClipboard and open the Wikipedia editor with a pre-populated sandbox link
3. **Step 3** — Confirm completion; logged to the backend

---

## Rake Tasks

All tasks are in `lib/tasks/import_ia_books.rake` under the `import` namespace:

| Task | Description |
|------|-------------|
| `import:jai_gyan` | Fetch all Kannada books from JaiGyan collection via IA API (paginated by year) |
| `import:servants_of_knowledge` | Fetch Kannada books from ServantsOfKnowledge (paginated by date range) |
| `import:compute_stats` | Deduplicate across both collections and compute aggregate stats |
| `import:to_backend[file]` | Post a JSON collection file to the backend API in batches of 50 |

**Notes on IA API pagination:**
- IA search `start` parameter is broken for large result sets
- Workaround: split queries by `year` (JaiGyan has <10k books/year) or `publicdate` range (ServantsOfKnowledge)
- `rows` parameter works reliably (capped at ~10,000)

---

## Configuration

### Environment

- **Development** — queries `localhost:3001` as backend
- **Production** — queries `samooha.sanchaya.net` as backend

Set in `app/models/book.rb`:
```ruby
BASE_URL = Rails.env == "development" ? 'http://localhost:3001' : 'https://samooha.sanchaya.net'
```

### Google Analytics

Tracker ID `UA-3727897-29` is configured in `config/environments/production.rb` and initialized in the layout via `<%= analytics_init if Rails.env.production? %>`.

### Locale

The app is fully Kannada (kn) locale. Set via `before_filter` in `ApplicationController`:
```ruby
def set_local_language
  I18n.locale = 'kn'
end
```

Translations are in `config/locales/kn.yml`.

---

## CSS & Branding

| Color | Usage |
|-------|-------|
| `#5F3792` | Primary brand purple — nav border, link hovers, stats numbers, table headers, card accents |
| `#2a1a33` | Footer background |
| `#333` | Body text, header text |
| `#999` / `#bbb` | Secondary text |

Font: **Noto Sans Kannada** (via Google Fonts) for full Kannada script support.

---

## File Structure

```
app/
├── assets/
│   ├── images/          — Logo, favicon, IA/Wikipedia icons, background
│   ├── javascripts/     — IME, validation, clipboard, application.js manifest
│   └── stylesheets/     — application.css.scss (main), books.css, categories.css.scss
├── controllers/         — books_controller.rb, categories_controller.rb
├── helpers/             — books_helper.rb, application_helper.rb
├── models/              — book.rb (PORO, no database)
└── views/
    ├── books/           — 16 files (index, wiki, stats, book lists, wiki guides)
    ├── categories/      — index.html.erb, show.html.erb
    ├── layouts/         — application.html.erb, _nav_social.html.erb
    └── kaminari/        — Pagination templates (7 files)

config/
├── locales/             — kn.yml, en.yml, kaminari-kn.yml
├── environments/        — production.rb, development.rb, test.rb
├── routes.rb
└── initializers/        — Kaminari, session, assets, etc.

db/                      — jai_gyan_books.json, servants_of_knowledge_books.json, stats.json
lib/tasks/               — import_ia_books.rake
public/assets/           — Precompiled fingerprinted assets
```

---

## Maintenance

### Restart Application
```bash
touch /home/pustaka/rails_apps/prod/current/tmp/restart.txt
```

### Recompile Assets
```bash
cd /home/pustaka/rails_apps/prod/current
bundle exec rake assets:precompile RAILS_ENV=production
touch tmp/restart.txt
```

### Refresh Book Statistics
```bash
cd /home/pustaka/rails_apps/prod/current
bundle exec rake import:compute_stats
```

### Reimport Books from Internet Archive
```bash
# Fetch all JaiGyan Kannada books
bundle exec rake import:jai_gyan

# Fetch ServantsOfKnowledge books (deduplicates against JaiGyan)
bundle exec rake import:servants_of_knowledge

# Recompute and save stats
bundle exec rake import:compute_stats
```

### Broken Link Filtering

The `broken_link?` helper filters out links to defunct domains:
- `dli.gov.in`
- `oudl.osmania.ac.in`
- `dli.ernet.in`
- `osmania` (catches underscore-encoded URLs like `oudl_osmania_ac_in`)

Internet Archive `archive_url` links are always shown regardless of the source library, since IA is a reliable host.

---

## Dependencies

| Gem | Purpose |
|-----|---------|
| `httparty` | HTTP client for backend API calls |
| `kaminari` | Pagination |
| `font-awesome-rails` | Icon font |
| `twitter-bootstrap-rails` | Bootstrap 3 UI framework |
| `devise` | Authentication |
| `zeroclipboard-rails` | Clipboard copy for wiki templates |
| `google-analytics-rails` | Google Analytics tracking |
| `jquery.ime` | Kannada input method editor (IME) |
| `therubyracer` | JavaScript runtime for asset pipeline |

---

## Testing

Tests use Rails default MiniTest:

```bash
bundle exec rake test
```

Test files are in `test/` — currently minimal (one book controller test, empty test classes for helpers and categories).

---

## Related Projects

- **Samooha Sanchaya** (https://samooha.sanchaya.net) — Backend API service for this app
- **Sanchaya** (https://sanchaya.org) — Parent organization: Kannada literature research platform
- **Patrike Sanchaya** (https://patrike.sanchaya.net) — Kannada newspaper archive portal (sibling project)
