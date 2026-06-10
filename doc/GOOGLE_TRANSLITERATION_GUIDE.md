# Kannada IME Rename Feature Guide

## Overview

When renaming publishers, authors, and libraries, you can now type in either English or Kannada script using the integrated Kannada IME (Input Method Editor). This allows you to:
- Keep English names as-is
- Create bilingual names (e.g., "Sahitya Akademi" or "ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ")
- Type in any language/script combination

## Where to Use

The Kannada IME is available when renaming:
- **Admin > Manage Publishers**
- **Admin > Manage Authors**
- **Admin > Manage Libraries**

## How to Use

### Simple Workflow

1. **Click Rename** on any publisher, author, or library
2. **Current Name** field shows the existing name
3. **New Name** field is ready for input with Kannada IME enabled
4. **Type the new name** using:
   - English text (typed directly)
   - Kannada script (using Kannada IME)
   - Or any combination
5. **Click Rename** to save

### Using Kannada IME

The Kannada IME is automatically available in the "New Name" field:

**To activate Kannada IME:**
- Start typing in the field
- The IME will activate (you'll see visual indicator)
- Type using standard Kannada IME rules

**To deactivate Kannada IME:**
- Press Escape or click outside the IME panel
- Return to typing English

**Example:**
```
Field: [Sahitya Akademi - ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ]
```

## Features

✅ **Kannada IME Support** - Full support for Kannada input  
✅ **Flexible Input** - Mix English and Kannada as needed  
✅ **No Auto-Conversion** - Full control over what you type  
✅ **Manual Entry** - You decide what name to use  
✅ **Bilingual Support** - Create multilingual names if desired  

## What Works

### English Names
- Type directly: "Sahitya Akademi"
- No special handling needed

### Kannada Names
- Activate IME and type using standard Kannada input method
- Result: "ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ"

### Bilingual Names (Optional)
- Type both English and Kannada in the same field
- Separate with space, dash, or pipes as desired
- Example: "Sahitya Akademi | ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ"

### Abbreviations & Special Cases
- Numbers, punctuation, special characters all supported
- Type naturally as needed

## Examples

| Original Name | New Name (Examples) |
|---------------|-------------------|
| Sahitya Akademi | ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ |
| Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್ |
| Akshar | ಅಕ್ಷರ |
| Priya Publications | ಪ್ರಿಯ ಪಬ್ಲಿಕೇಶನ್ಸ್ |
| Veeraloka Books | ವೀರಲೋಕ ಬುಕ್ಸ್ |

## Kannada IME Rules

The Kannada IME follows standard ITRANS/phonetic rules:

### Basic Consonants
- k → ಕ, g → ಗ, ch → ಚ, j → ಜ, t → ಟ, d → ಡ, p → ಪ, b → ಬ, m → ಮ, y → ಯ, r → ರ, l → ಲ, v → ವ, sh → ಶ, s → ಸ, h → ಹ, n → ನ

### Vowels
- a → ಅ, aa → ಆ, i → ಇ, ii → ಈ, u → ಉ, uu → ಊ, e → ಎ, ee → ಏ, o → ಒ, oo → ಓ

### Consonant Clusters
- kh → ಖ, gh → ಘ, ch → ಚ, chh → ಛ, jh → ಝ, th → ಠ, dh → ಢ, bh → ಭ, ph → ಫ, sh → ಶ, sh → ಷ

**Note:** IME behavior may vary based on system settings and the specific IME implementation.

## Troubleshooting

### IME Not Activating
1. Click on the "New Name" field
2. The IME should activate automatically
3. If not, check your system's IME settings

### Can't type in Kannada
- Ensure Kannada IME is installed on your system
- Check if IME is properly configured
- Try clicking the field again and typing

### Can't switch between English and Kannada
- Press Escape to exit IME mode
- Type English normally
- Click field again to activate IME for Kannada

### Text looks wrong after typing
- IME display is based on system font rendering
- If font doesn't support Kannada, text may appear incorrect
- Try refreshing the page or using a different browser

## Best Practices

1. **Decide on naming convention first** - Will you use English, Kannada, or both?
2. **Be consistent** - Similar entities should have similar naming patterns
3. **Test after typing** - Review the result before clicking Rename
4. **Use proper spelling** - Correct English/Kannada spelling ensures proper indexing
5. **Document your choices** - Note which entities use which naming convention

## Limitations

❌ **No auto-transliteration** - You must type the Kannada yourself  
❌ **Depends on system IME** - Quality depends on OS/system configuration  
❌ **No validation** - System accepts any input you provide  
❌ **No suggestions** - No auto-complete or suggestions available  

## FAQ

**Q: Can I undo a rename?**  
A: Yes—go to Admin > Corrections & Edits and click Undo on the incorrect rename.

**Q: What if I make a typo?**  
A: Click Rename again on the same item and fix the name.

**Q: Can I use other scripts (Tamil, Telugu, etc.)?**  
A: Yes, if you have those IMEs installed on your system and the field supports them.

**Q: Do I have to use Kannada?**  
A: No—you can keep names in English if you prefer.

**Q: Will the name change affect existing books?**  
A: Yes—all books with that publisher/author/library will be updated with the new name.

**Q: Can I revert a rename?**  
A: Yes—use the Undo feature in Corrections & Edits, or rename again with the old name.

**Q: What's the best format for bilingual names?**  
A: Use "English | ಕನ್ನಡ" format, but any format works. Be consistent across all names.

## Tips for Success

1. **Copy from reliable sources** - Use official publisher/author/library websites for correct names
2. **Test on small batches first** - Rename a few test items before bulk operations
3. **Keep audit trail** - The system logs all renames in Corrections & Edits for review
4. **Use clear naming** - Avoid abbreviations unless necessary
5. **Verify after rename** - Check that books still appear correctly with new names

## Support

For issues with:
- **IME not working** - Check your system's language/input settings
- **Rename not saving** - Check browser console for errors
- **Text rendering** - Ensure your browser/OS supports Kannada fonts
- **Other issues** - Contact admin with description of the problem
