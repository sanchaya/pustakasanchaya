# Google Transliteration Feature Guide

## Overview

The Google Transliteration feature allows you to automatically convert English names to Kannada when renaming publishers, authors, and libraries. This creates bilingual names (English | ಕನ್ನಡ) for better searchability and localization.

## Where to Use

Transliteration is available in the **Rename** modals for:
- **Admin > Manage Publishers**
- **Admin > Manage Authors**
- **Admin > Manage Libraries**

## How to Use

### Step-by-Step

1. **Click the Rename button** for any publisher, author, or library
2. **Enter the English name** in the "New Name (English)" field
   - Example: `Sapna Book House`
3. **Click the "Transliterate" button** (or press Enter)
   - The button shows a language icon: <i class="fas fa-language"></i>
   - A dialog appears showing "Transliterating..."
4. **Result appears in "New Name (Full)" field**
   - Format: `English name | ಕನ್ನಡ ಹೆಸರು`
   - Example: `Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್`
5. **Optional: Edit the Kannada text** if needed
6. **Click Rename** to save the bilingual name

### Keyboard Shortcut

- Type the English name in the "New Name (English)" field
- Press **Enter** to auto-trigger transliteration
- No need to click the button!

## What It Does

### Transliteration

Converts English text to Kannada using Google's Transliteration API:

```
Input:  "Abhinava"
Output: "Sapna Book House | ಅಭಿನವ"
```

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

### JavaScript API

The feature uses `transliterateAndFill()` function:

```javascript
// Simple usage
transliterateAndFill('Sapna Book House', 'renameNewName');

// Fills the field with:
// "Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್"
```

### Google Transliteration API

- **Service**: Google Transliteration API (`google.language.transliterate`)
- **Language**: Kannada (language code: `kn`)
- **Loading**: Loaded automatically via `google-transliteration.js`

### Error Handling

If transliteration fails:
- The English text is still placed in the field
- You can manually add the Kannada text
- Or just save the English-only name

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

#### Issue: "Transliteration failed - enter manually"

- Google API may not be loaded yet
- **Solution**: Wait a few seconds and try again
- **Alternative**: Type the Kannada text manually

#### Issue: Kannada text looks wrong

- Google may have transliterated incorrectly
- **Solution**: Manually fix the Kannada text in the field
- **Example**: "Sapna" might be "ಸಪ್ನ" instead of "ಸಾಪ್ನ"

#### Issue: Button is disabled/unresponsive

- JavaScript may not have loaded
- **Solution**: Refresh the page and try again
- **Check**: Open DevTools (F12) and check console for errors

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

### Q: Is transliteration instant?

**A**: Usually yes (1-2 seconds), but:
- First time loads Google API (slower, ~5 seconds)
- Subsequent transliterations are faster
- Network latency may affect speed

## Requirements

- **Internet Connection**: Required to call Google Transliteration API
- **Modern Browser**: Chrome, Firefox, Safari, Edge (all recent versions)
- **JavaScript Enabled**: Required for transliteration to work

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
