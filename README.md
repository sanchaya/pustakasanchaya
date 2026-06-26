# Pustaka Sanchaya (ಪುಸ್ತಕ ಸಂಚಯ)

Kannada book search portal — aggregates books from digital libraries (Internet Archive, ServantsOfKnowledge, Osmania, DLI, and others) and online stores (Ankita Pustaka, Total Kannada, Navakarnataka, Kannada Book House, etc.) with a searchable catalog, category browsing, author/publisher indexes, and Wikipedia article creation workflow.

**Production:** https://pustaka.sanchaya.net  
**Ruby:** 2.4.6 | **Rails:** 4.2.11.1 | **Database:** MySQL | **Server:** Phusion Passenger + nginx

---

## Architecture

Rails application with a MySQL database. Book metadata, authors, publishers, categories, and store links are stored locally with cached slug maps for SEO-friendly URLs.

## Key Features

- **Search** — Full-text search across 122,000+ Kannada books
- **Categories** — Browse by category with letter-based filtering
- **Authors** — 40,000+ authors with index/show pages, slug-based URLs
- **Publishers** — 13,500+ publishers with index/show pages, slug-based URLs
- **Stores** — 31 active online stores/libraries with logos and per-book links
- **Wikipedia Integration** — Three-step workflow for creating Kannada Wikipedia book articles
- **Admin Panel** — Book editing, author/publisher/library/store merge/rename, corrections, audit log

## Database

The `books` table has 122,000+ records with columns for:
- `name`, `name_kannada`, `name_latin`, `name_english`
- `author`, `author_kannada`, `author_latin`, `author_slug`
- `publisher`, `publisher_kannada`, `publisher_latin`, `publisher_slug`
- `library`, `categories`, `year`, `book_link`, `archive_url`
- `thumbnail`, `source_identifier`, `merged_sources`

Supporting tables: `stores`, `book_stores`, `people`, `corrections`, `suggestions`, `wiki_users`

### Slug System

SEO-friendly Latin-slug URLs for authors, publishers, and categories:
- `SlugHelper.slug_for(name)` — uses `parameterize` with MD5 hex fallback for pure-Kannada names
- Collision handling with `-1`, `-2` suffixes (priority by book count)
- Hybrid DB + Cache: `author_slug`/`publisher_slug` columns for fast indexed DB lookup; cached slug maps for index pages
- Cache keys (`slug_map:*`, `slug_pairs:*`) expire in 24 hours, pre-warmed via rake task

## Setup

```bash
bundle install
rake db:migrate
rails server
```

### Rake Tasks

| Task | Description |
|------|-------------|
| `slugs:setup` | Backfill slug columns, warm cache |
| `slugs:backfill` | Recompute `author_slug`/`publisher_slug` on books |
| `slugs:warm_cache` | Pre-warm all 6 slug cache keys |
| `store:download_logos` | Download all store logos to `public/images/store-logos/` |

## Routes

| Path | Description |
|------|-------------|
| `/` | Homepage — search + stats |
| `/categories` | Category browser with letter bar |
| `/categories/:slug` | Books in a category |
| `/authors` | Author index with letter bar |
| `/authors/:slug` | Books by author |
| `/publishers` | Publisher index with letter bar |
| `/publishers/:slug` | Books by publisher |
| `/stores` | Stores and libraries listing |
| `/wiki` | Wikipedia article creation workflow |
| `/admin` | Admin dashboard |

## Mobile

Responsive layout using Bootstrap 3 with custom mobile CSS for screens down to 320px width.

## Maintenance

```bash
# Restart
touch tmp/restart.txt

# Precompile assets
bundle exec rake assets:precompile RAILS_ENV=production

# Backfill slugs after data merge/rename
bundle exec rake slugs:setup
```