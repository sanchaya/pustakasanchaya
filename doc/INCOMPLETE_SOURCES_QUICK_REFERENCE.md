# Incomplete Publisher Data - Quick Reference

## At a Glance

| Source | Books | Issue | Severity |
|--------|-------|-------|----------|
| **Sahitya** | 1,779 | 100% portal default | 🔴 High |
| **Bahuroopi** | 233 | 99.6% portal default | 🔴 High |
| **Sawanna** | 66 | 93% portal default + SPA | 🔴 High |
| **Navakarnataka** | 1,484 | 18.3% portal default | 🟡 Medium |
| **Veeraloka** | 4,931 | 90.8% portal default | 🟡 Medium |

**Total:** 8,493 books with incomplete publisher data (15.8% of 53,903)

---

## What This Means

### For End Users
- Books from these sources may show the **portal/aggregator name** instead of the actual publisher
- Example: A book on Sahitya might show "Sahitya Books" as publisher instead of "Abhinava Publications"
- To find books by specific publishers, avoid filtering by these sources if accuracy is critical

### For Administrators
- These sources have been validated and flagged in `corrections.json`
- Publisher data **should NOT be auto-corrected** (scraping is unreliable)
- Individual books **can be manually corrected** via the admin interface
- Users **cannot easily query** books from these sources by true publisher

---

## Source Details

### 🔴 HIGH SEVERITY

#### Sahitya (1,779 books, 100% affected)
- **Problem:** Original scraper defaulted all books to "Sahitya Books"
- **Why:** WooCommerce site - no individual publisher in consistent location
- **Status:** Portal name is the aggregator; real publishers unknown
- **Recommendation:** Accept as-is; manual corrections only for high-priority books

#### Bahuroopi (233 books, 99.6% affected)
- **Problem:** Original scraper defaulted almost all books to "Bahuroopi"
- **Why:** Anti-bot measures block scraping; only 1 book has different publisher
- **Status:** Portal name is accurate for most books
- **Recommendation:** Accept as-is; manual corrections only if needed

#### Sawanna (66 books, 93% affected)
- **Problem:** Original scraper defaulted most books to "Sawanna Enterprises"
- **Why:** Website is a single-page app (hash routing) - cannot scrape without browser
- **Status:** Portal name is the distributor; real publishers not scrapeable
- **Recommendation:** Accept as-is; would need Selenium/Puppeteer to fix

### 🟡 MEDIUM SEVERITY

#### Navakarnataka (1,484 books, 18.3% affected)
- **Problem:** 1,484 of 8,108 books default to "Navakarnataka Publications"
- **Why:** Original scraper partially worked - captured data for some, defaulted for others
- **Status:** Majority (6,624 books) have correct publishers; minority have defaults
- **Recommendation:** Fix the 1,484 defaulted books if possible; majority are already correct

#### Veeraloka (4,931 books, 90.8% affected)
- **Problem:** 4,931 of 5,431 books default to "Veeraloka Books"
- **Why:** Original scraper captured only first ~500 books in detail; rest defaulted
- **Status:** 206 books have correct publishers; 4,931 have defaults; 277 blank
- **Recommendation:** Check if original JSON file has publisher data hidden elsewhere; manual fixes for high-value books

---

## How to Handle in Admin

### When User Reports Wrong Publisher

1. **Check source:** Is this book from an incomplete source?
   - Admin Panel → Books → Filter by source
   
2. **If incomplete source:**
   - Acknowledge it's a known limitation
   - Offer to manually correct if it's an important book
   - Don't promise automated fixes (they're unreliable)

3. **To manually correct:**
   - Admin Panel → Books → Edit → Change Publisher field
   - Save changes
   - Change is logged in corrections.json automatically

4. **For bulk corrections:**
   - Use Admin → Metadata → Publishers → Search/Merge features
   - Or write a custom rake task for specific corrections

---

## Data Quality Flags

All 5 incomplete sources have been flagged in `db/corrections.json`:

```json
{
  "type": "data_quality_flag",
  "source_identifier": "sahitya|bahuroopi|sawanna|navakarnataka|veeraloka",
  "field": "publisher",
  "status": "incomplete_data",
  "severity": "high|medium"
}
```

These can be queried programmatically:

```ruby
# Ruby/Rails
incomplete_sources = Book.where(source_identifier: 
  %w[sahitya bahuroopi sawanna navakarnataka veeraloka])

# Find all books from incomplete sources
incomplete_books = incomplete_sources.count

# Group by source
by_source = incomplete_sources.group(:source_identifier).count
```

---

## Queries & Reports

### View All Incomplete Source Books
```bash
cd /app && rails c
Book.where(source_identifier: %w[sahitya bahuroopi sawanna navakarnataka veeraloka]).count
```

### Generate Validation Report
```bash
bundle exec rake publishers:validate_all_sources
# Output: tmp/publisher_validation_report.json
```

### View Data Quality Flags
```bash
bundle exec rake publishers:validate_all_sources | grep -A 50 "INCOMPLETE"
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| `doc/PUBLISHER_DATA_QUALITY.md` | Full technical documentation |
| `doc/INCOMPLETE_SOURCES_QUICK_REFERENCE.md` | This file - quick answers |
| `tmp/publisher_validation_report.json` | Detailed validation results |
| `tmp/incomplete_sources_summary.json` | Summary of flagged sources |
| `lib/tasks/validate_publisher_data.rake` | Validation task |
| `lib/tasks/mark_incomplete_sources.rake` | Metadata flagging task |

---

## Future Improvements

### Short Term
- Accept manual corrections via admin panel
- Display badges on books from incomplete sources
- Filter/sort by data quality in search

### Medium Term
- Contact portals for API access to real publisher data
- Implement browser-based scraping (Headless Chrome) for Sawanna
- Cross-reference with ISBN databases

### Long Term
- Machine learning to infer publishers from metadata
- Community crowdsourcing of publisher corrections
- Periodic re-scraping with improved techniques

---

## Quick Links

- **Full Documentation:** `doc/PUBLISHER_DATA_QUALITY.md`
- **Validation Reports:** `tmp/publisher_validation_report.json`
- **Rake Tasks:** `lib/tasks/validate_publisher_data.rake`, `lib/tasks/mark_incomplete_sources.rake`
- **Admin Interface:** http://localhost:3000/admin/publishers
- **Questions:** Ask in #data-quality Slack channel

---

*Last Updated: June 10, 2026*  
*Status: ✓ Data Validation Complete*
