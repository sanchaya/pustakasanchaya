# Google Transliteration Feature Guide

## Overview

The Google Transliteration feature allows you to automatically convert English names to Kannada when renaming publishers, authors, and libraries. This creates bilingual names (English | ಕನ್ನಡ) for better searchability and localization.

## Where to Use

Transliteration is available in the **Rename** modals for:
- **Admin > Manage Publishers**
- **Admin > Manage Authors**
- **Admin > Manage Libraries**

## How to Use

### Automatic (Recommended)

1. **Click the Rename button** for any publisher, author, or library
2. **Type the English name** in the "New Name (English)" field
   - Example: `Sapna Book House`
3. **Wait 800ms** or click the "Transliterate" button
   - Auto-transliteration happens automatically after you stop typing
   - Or click the ✨ **Transliterate** button to trigger immediately
4. **Result auto-fills** in the "New Name (Full)" field
   - Shows: `Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್`
   - Field is read-only (to prevent accidental edits)
5. **Click Rename** to save the bilingual name

### Manual Trigger

If auto-transliteration doesn't happen:
- Click the ✨ **Transliterate** button
- Or press **Enter** in the English name field

### What Transliteration Does

Converts English → English | ಕನ್ನಡ format:

```
Input:  Sapna Book House
Result: Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್
```

The system uses **two transliteration services**:
1. **Google Transliteration** (if available)
2. **Aksharamukha API** (fallback) - always works

## What It Does

### Automatic Transliteration

The system **automatically converts English to Kannada**:

```
Type:     Sapna Book House
Wait:     800ms (or click button)
Result:   Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್
```

### Dual Transliteration Engine

Two APIs work together for reliability:

1. **Google Transliteration** (Primary)
   - Fast and accurate
   - May not always be available
   
2. **Aksharamukha API** (Fallback)
   - Always available
   - Free, no API key needed
   - Converts en_US → kn_KN

If Google fails → Automatically tries Aksharamukha  
If both fail → Shows English-only name

### Bilingual Names

Creates dual-language names for better UX:

```
Old: ಸಪ್ನ ಬುಕ್ ಹೌಸ್ (only Kannada, hard to search in English)

New: Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್ (searchable in both languages)
```

### Benefits

1. **Better Search**: Users can search in English OR Kannada
2. **Localization**: Kannada speakers see native text
3. **Clarity**: English readers see readable English
4. **Consistency**: All names follow standard format

## Format Explanation

### "English name | ಕನ್ನಡ ಹೆಸರು"

- **English name**: The publisher/author/library name in English
- **|** : Pipe separator (ASCII 124)
- **ಕನ್ನಡ ಹೆಸರು**: The same name transliterated to Kannada

### Examples

```
Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್
Abhinava | ಅಭಿನವ
Harivu Publications | ಹರಿವು ಪ್ರಕಾಶನ
Penguin Random House | ಪೆಂಗ್ವಿನ್ ರ್ಯಾಂಡಮ್ ಹೌಸ್
```

## How It Works (Technical)

### Automatic Transliteration Process

1. **User types English name**
   - Example: `Sapna Book House`

2. **System waits 800ms** (debounce)
   - Avoids API calls on every keystroke
   - Waits for user to stop typing

3. **Calls `transliterateAndFill()`**
   - Tries Google Transliteration API
   - If fails, tries Aksharamukha API
   - If both fail, uses English-only

4. **Result auto-fills** in read-only field
   - Format: `English | ಕನ್ನಡ`
   - No manual editing needed

### Dual API Architecture

**Google Transliteration** (Primary)
```
Request: transliterate('Sapna', 'en', 'kn')
Result: 'ಸಪ್ನ'
```

**Aksharamukha API** (Fallback)
```
Request: https://www.aksharamukha.appspot.com/api/transliterate
         ?text=Sapna&from=en_US&to=kn_KN
Response: { "result": "ಸಪ್ನ" }
```

### ES5 Compatible

- Written in ES5 JavaScript (Rails 4.2 compatible)
- No external libraries required
- Works in all modern browsers
- Minified in production assets

## Tips & Best Practices

### Formatting Tips

1. **Proper English First**: Make sure English is correct
   - ✓ `Sapna Book House` (correct)
   - ✗ `sapna book house` (will transliterate differently)
   - ✗ `SAPNA BOOK HOUSE` (all caps)

2. **Spacing**: Google handles spacing well
   - `Sapna Book House` → `ಸಪ್ನ ಬುಕ್ ಹೌಸ್` ✓
   - `SapnaBookHouse` → `ಸಪ್ನಾಬುಕ್ಹೌಸ್` (no spaces) ✗

3. **Special Characters**: Keep only alphanumeric
   - `Sapna Book House` ✓
   - `Sapna (Book House)` (parentheses) - may not transliterate well
   - `Sapna & Co.` (ampersand) - may have issues

### Editing Tips

1. **Always Review**: Check the Kannada text before saving
2. **Manual Edits**: Feel free to edit the Kannada if needed
3. **Format Consistency**: Keep the "English | ಕನ್ನಡ" format

### Common Issues

#### Issue: Result field is empty after clicking Transliterate

**Causes:**
- Both Google and Aksharamukha APIs failed
- Internet connection issue
- English name field is empty

**Solutions:**
1. Try again - sometimes APIs have temporary issues
2. Check internet connection
3. Make sure English name is entered
4. Open DevTools (F12 → Console) to see error messages

#### Issue: Transliteration shows wrong Kannada text

**Possible causes:**
- API limitation (some transliterations are non-trivial)
- Proper nouns might be transliterated as common words

**Solutions:**
1. Manual typing - Enable IME and type correct Kannada
2. Copy and paste - If you have the correct Kannada text
3. Contact admin - For frequently needed corrections

#### Issue: Transliteration takes too long

**Normal behavior:**
- First time: 2-3 seconds (API loading)
- Subsequent: 1-2 seconds
- Aksharamukha fallback: 1-2 seconds

**If taking longer than 5 seconds:**
1. Check internet connection
2. Try clicking button again
3. Refresh page and retry

## Frequently Asked Questions

### Q: Can I have only English or only Kannada?

**A**: Yes. The transliteration feature creates bilingual names, but you can:
- Save English-only: Type just the English name
- Keep current Kannada: Don't use transliterate button
- Result: The field accepts any format

### Q: What if the transliteration is wrong?

**A**: Manually edit the Kannada text:
1. The field is editable after transliteration
2. Fix any incorrect Kannada characters
3. Save with the corrected text

### Q: Does this affect existing books?

**A**: Yes, when you rename a publisher/author/library:
- All books using that publisher/author/library are updated
- The new bilingual name appears in all book records
- This is tracked in the Corrections & Edits log

### Q: Can I undo a transliteration?

**A**: Yes:
1. Go to **Admin > Corrections & Edits**
2. Find the rename you want to undo
3. Click the red **Undo** button
4. The name reverts to the previous value

### Q: How fast is transliteration?

**A**: Very fast!
- First click: 2-3 seconds (APIs load)
- Subsequent: 1-2 seconds
- Automatic (after typing): 800ms delay + 1-2 seconds API call

### Q: Does it work if internet is down?

**A**: No, it requires internet for both Google and Aksharamukha APIs. If offline, you must enter the name manually.

## Requirements

- **Internet Required**: Both APIs need internet connection
- **Modern Browser**: Chrome, Firefox, Safari, Edge (all recent versions)
- **JavaScript Enabled**: Required for transliteration to work
- **No Special Software**: No keyboard configuration needed

### APIs Used

1. **Google Transliteration API**
   - Loaded from: `www.google.com/inputtools/js/lang_kn.js`
   - No API key required
   - May be unavailable in some regions

2. **Aksharamukha API**
   - Endpoint: `https://www.aksharamukha.appspot.com/api/transliterate`
   - Free and always available
   - Fallback when Google fails

## Browser Compatibility

| Browser | Support |
|---------|---------|
| Chrome | ✓ Full support |
| Firefox | ✓ Full support |
| Safari | ✓ Full support |
| Edge | ✓ Full support |
| IE 11 | ✗ Not supported |

## Support & Troubleshooting

### Debug Steps

1. **Open Developer Tools**: F12 or Right-click > Inspect
2. **Go to Console tab**
3. **Try transliterating again**
4. **Look for error messages**

Common console messages:
- `"Google Transliteration API loaded"` - Good, API is ready
- `"Transliteration error: ..."` - API call failed, check error
- `"Transliterator not ready"` - Wait and try again

### Check Internet Connection

Google API requires internet access:
1. Open any Google service in another tab
2. If it loads, internet is fine
3. If not, check your network connection

### Contact Support

If transliteration doesn't work:
1. Check browser console for errors (F12 → Console)
2. Verify internet connection
3. Try a different browser
4. Contact admin team with error message

## See Also

- **Rename & Merge Guide**: For general rename/merge operations
- **Corrections & Edits Guide**: For undoing changes
- **Admin Management**: For other metadata operations

---

*Last Updated: June 10, 2026*  
*Feature: Google Transliteration API*  
*Status: Active*
