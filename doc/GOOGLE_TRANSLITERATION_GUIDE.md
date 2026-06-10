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
   - The button shows a language icon: 🌐
   - The "New Name (Full)" field is pre-filled with: `Sapna Book House | `
4. **Type or paste the Kannada text** in the "New Name (Full)" field
   - The cursor is already positioned after the pipe `|`
   - Use the Kannada IME tool (already enabled) to type
   - Or paste Kannada text if you have it
   - Example result: `Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್`
5. **Click Rename** to save the bilingual name

### Keyboard Shortcut

- Type the English name in the "New Name (English)" field
- Press **Enter** to auto-fill the field and position cursor
- Start typing Kannada immediately using the IME
- No need to manually click the button or position cursor!

## What It Does

### Transliteration Helper

The "Transliterate" button helps you create bilingual names:

1. Pre-fills the "New Name (Full)" field with `English name | `
2. Positions the cursor after the pipe
3. Activates the Kannada IME for typing
4. You then type or paste the Kannada text

```
Before: "Sapna Book House" (English only)
              ↓ Click Transliterate
After: "Sapna Book House | " (ready for Kannada)
              ↓ Type/Paste Kannada
Result: "Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್" (bilingual)
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

### JavaScript Implementation

The feature uses `transliterateAndFill()` function:

```javascript
// Simple usage
transliterateAndFill('Sapna Book House', 'renameNewName');

// Fills the field with:
// "Sapna Book House | "
// And positions cursor after the pipe for Kannada entry
```

### Kannada IME

- **IME Tool**: Kannada Input Method Editor (built into the app)
- **Activation**: Auto-enabled when field is focused
- **How**: You type English characters, it converts to Kannada
- **Example**: Type "sapna" → shows "ಸಪ್ನ" as suggestion

### No External API Required

- Uses local IME tool (no internet needed for typing)
- Can type or paste Kannada text
- Fully functional even without external services
- More reliable than API-dependent solutions

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

#### Issue: Field shows "English name | " but I can't type Kannada

- The Kannada IME might not be active
- **Solution**: Click in the field again to activate IME
- **Check**: Look for IME indicator in the field
- **Alternate**: Click the language button in the IME panel to switch to Kannada

#### Issue: I see a cursor but nothing happens when I type

- The IME might be disabled
- **Solution**: Check if IME is active (should show "Kannada" indicator)
- **Activate**: Click the IME toggle button or press Ctrl+G
- **Alternative**: Copy and paste Kannada text instead

#### Issue: Button doesn't respond

- JavaScript may not have loaded properly
- **Solution**: Refresh the page and try again
- **Check**: Open DevTools (F12 → Console) for errors

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

**A**: Yes, the button instantly pre-fills the field and positions the cursor. Then you type Kannada at your own pace using the IME tool.

## Requirements

- **No Internet Required**: Works completely offline (uses local IME)
- **Modern Browser**: Chrome, Firefox, Safari, Edge (all recent versions)
- **JavaScript Enabled**: Required for the feature to work
- **Kannada Keyboard/IME**: System should support Kannada input (pre-configured)

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
