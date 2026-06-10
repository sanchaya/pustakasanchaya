# Undo Functionality - Troubleshooting Guide

## Overview
The Undo button in **Admin > Corrections & Edits** allows you to revert any book field edit to its previous value. When you undo an edit:

1. The book field is reverted to its old value
2. A new correction record is created logging the undo action
3. The original edit record is deleted
4. The page reloads to show the updated state

## How to Undo an Edit

1. Go to **Admin > Corrections & Edits**
2. Find the edit you want to undo in the table
3. Click the red **Undo** button
4. Confirm the action in the popup dialog
5. Wait for the button to show "Undone" (check mark)
6. Page will reload automatically

## What Should Happen

### Success Flow
- Button changes to spinner icon: `⏳ Undoing...`
- Button becomes disabled
- After 1-2 seconds: Button shows check mark: `✓ Undone`
- Row fades (becomes semi-transparent)
- Page automatically reloads after ~1.5 seconds
- Undo edit disappears from the table
- New "UNDO" entry appears at top showing the reversion

### If Something Goes Wrong

#### Issue: Button stays on spinner icon indefinitely

**Solution 1: Check browser console**
1. Open browser DevTools (F12 or right-click > Inspect)
2. Go to "Console" tab
3. Look for any red error messages
4. Share the error with the admin team

**Solution 2: Check server logs**
```bash
# SSH into server
cd /home/pustaka/rails_apps/prod/current

# View last 50 lines of production log
tail -50 log/production.log

# Or follow live logs
tail -f log/production.log
# Then click undo button and watch for error messages
```

**Solution 3: Clear cache and try again**
1. Hard refresh page: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Try clicking undo again

#### Issue: Alert appears: "Edit not found"
- The edit ID might be wrong
- The database might be corrupted
- Try refreshing the page and trying again

#### Issue: Alert appears: "Book not found"
- The book's source_identifier might have changed
- The book might have been deleted
- The edit record is orphaned
- Admin needs to manually investigate

#### Issue: Alert appears: "Cannot undo - source identifier missing"
- The correction record in the database is incomplete
- This shouldn't happen with new records
- Contact admin team

#### Issue: Button shows error message
- Read the specific error and report it to admin
- Check server logs (see Solution 2 above)

## How It Works (Technical Details)

### Architecture

```
User clicks "Undo" button
        ↓
JavaScript confirms action
        ↓
Sends DELETE request with:
  - edit_id (from button)
  - CSRF token (from page meta tag)
  - JSON payload
        ↓
Rails routes to: DELETE /admin/corrections
        ↓
Admin::CorrectionsController#destroy action:
  1. Find correction record by ID
  2. Find book by source_identifier
  3. Revert book field to old_value
  4. Create new correction record logging the undo
  5. Delete original correction record
  6. Return JSON response { success: true }
        ↓
JavaScript:
  1. Receives success response
  2. Marks row as "Undone"
  3. Waits 1.5 seconds
  4. Reloads page (which queries fresh data)
        ↓
Page refreshes and shows updated state
```

### Database Changes

When you undo an edit, here's what happens in the database:

**Before Undo:**
```
corrections table:
ID: 123
source_identifier: "book_abc"
field: "publisher"
old_value: "Old Publisher"
new_value: "New Publisher"
```

**After Undo:**
```
corrections table:
ID: 124 (NEW RECORD - the undo action)
source_identifier: "book_abc"
field: "publisher"
old_value: "New Publisher"
new_value: "Old Publisher"
description: "UNDO: Reverted publisher from 'New Publisher' back to 'Old Publisher'"

ID: 123 (DELETED - the original edit is removed)
```

**books table (source_identifier="book_abc"):**
```
publisher: "Old Publisher"  (reverted)
```

### Audit Trail

All undo actions are logged:
- Go to **Admin > Audit Log** to see all changes
- Look for entries with "UNDO:" in the description
- This preserves a complete history of all edits and reversions

## Common Scenarios

### Scenario: You accidentally changed an author name

1. Go to **Admin > Corrections & Edits**
2. Find the edit that changed the author name
3. Click **Undo**
4. Confirm
5. The author name reverts to the original value
6. A new "UNDO" record is created showing the reversion

### Scenario: You want to undo multiple edits

1. Go to **Admin > Corrections & Edits**
2. For each edit you want to undo, click **Undo**
3. Handle them one by one (they're fast)
4. Each undo creates a corresponding "UNDO" record in the audit trail

### Scenario: You undo the wrong edit

1. Undo created a new record showing the reversion
2. You can then undo that "UNDO" record to re-apply the original change
3. This creates another record in the audit trail
4. You always have a complete history

## Browser Requirements

- Modern browser with Fetch API support
- JavaScript enabled
- Cookies enabled (for session management)
- CSRF token present in page meta tags

## Troubleshooting Checklist

If undo doesn't work:

- [ ] Is JavaScript enabled in your browser?
- [ ] Are you logged in as admin? (check top right of page)
- [ ] Can you see the "Undo" button? (it's red, far right of each row)
- [ ] Does the button become disabled when clicked? (if not, JS might not be running)
- [ ] Can you see the spinner icon? (if not, button might not be responding)
- [ ] Check browser console for errors (F12 → Console)
- [ ] Check server logs for errors (tail -f log/production.log)
- [ ] Try hard-refreshing the page (Ctrl+Shift+R)
- [ ] Try a different browser
- [ ] Contact admin team with error messages from console and logs

## Success Indicators

After clicking undo, you should see:

1. ✓ Button becomes disabled immediately
2. ✓ Button shows spinner icon
3. ✓ After ~1 second, button shows check mark
4. ✓ Row becomes semi-transparent (fades)
5. ✓ After ~1.5 seconds, page reloads
6. ✓ Undo row disappears from table
7. ✓ New "UNDO:" entry appears in audit log

If all 7 indicators happen, undo was successful.

## Contact & Support

For issues with undo:
1. Check this guide first
2. Check browser console (F12)
3. Check server logs
4. Report to admin team with:
   - Screenshot of error
   - Browser console error messages
   - Server log excerpt
   - Which book/edit you were trying to undo

---

*Last Updated: June 10, 2026*  
*Version: 1.0*
