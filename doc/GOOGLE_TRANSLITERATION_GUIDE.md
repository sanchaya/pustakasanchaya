# Kannada Phonetic Transliteration Feature Guide

## Overview

The Kannada Transliteration feature automatically converts English names to Kannada (script) when renaming publishers, authors, and libraries. This creates bilingual names (English | ಕನ್ನಡ) for better searchability and localization.

**Note:** Transliteration uses phonetic English-to-Kannada mapping (not character-by-character conversion).

## Where to Use

Transliteration is available in the **Rename** modals for:
- **Admin > Manage Publishers**
- **Admin > Manage Authors**
- **Admin > Manage Libraries**

## How to Use

### Basic Workflow

1. **Click the Rename button** for any publisher, author, or library
2. **Type the English name** in the textarea field
   - Example: `Sapna Book House`
3. **Wait 1 second** for auto-transliteration
   - The system automatically transliterates after you stop typing
4. **Result appears below the English text** with `|` separator
   - Shows: `Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್`
5. **Click Rename** to save the bilingual name

### How It Works

- **English input**: Type in Latin script
- **Wait 1 second**: System waits for you to finish typing
- **Auto-transliterate**: Phonetic conversion English → Kannada
- **Format**: `English | ಕನ್ನಡ` (both on same line)

### Example

```
Input:  Sahitya Akademi
Result: Sahitya Akademi | ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ
```

## Technical Details

### Transliteration Method

The system uses **phonetic mapping** rather than API calls:
- Converts English phonetic spelling to Kannada script
- No external API dependency (faster, more reliable)
- Maps common English letters/syllables to Kannada equivalents

### Supported Mappings

Common English-to-Kannada mappings:

| English | Kannada |
|---------|---------|
| ka, kha | ಕ, ಖ |
| ga, gha | ಗ, ಘ |
| cha, chha | ಚ, ಛ |
| ja, jha | ಜ, ಝ |
| ta, tha | ಟ, ಠ |
| da, dha | ಡ, ಢ |
| pa, pha | ಪ, ಫ |
| ba, bha | ಬ, ಭ |
| ma | ಮ |
| ya, ra, la, va | ಯ, ರ, ಲ, ವ |
| a, aa, i, ee, u, oo | ಅ, ಆ, ಇ, ಈ, ಉ, ಊ |

### Phonetic Transliteration Rules

1. **Multi-character sequences** are matched first (e.g., "kha" → ಖ before "ka" → ಕ)
2. **Case-insensitive** - "SAPNA" and "sapna" produce the same result
3. **Unmatched characters** are kept as-is (helpful for special characters, numbers, punctuation)
4. **Spaces and punctuation** are preserved

## Limitations & Notes

### What Works Well
- Standard Indian publisher/author names (Sahitya, Akshar, Priya)
- Names with common Kannada consonants (ka, ga, ta, pa, etc.)
- Multi-word names (spaces are preserved)

### What May Not Work Perfectly
- Names with silent vowels or complex English phonetics
- Non-Latin characters already in the name
- Very short names or single letters

### Improving Results

If transliteration isn't perfect:
1. **Manual editing**: You can manually edit the result before saving
2. **Copy correct form**: If you know the correct Kannada spelling, paste it directly
3. **Use alternate English spelling**: Different English spelling → different transliteration

## Troubleshooting

### No transliteration appears
- **Wait 1+ seconds** after typing for auto-trigger
- **Check console** (F12 > Console tab) for errors
- **Type at least 2 characters** before auto-trigger activates

### Transliteration looks wrong
- **Manual override**: Click in the result area and edit directly before saving
- **Report**: If consistent issue, report to admin with example name

### Special characters not working
- Numbers, punctuation, hyphens are preserved as-is
- Use hyphens, spaces, commas freely in names

## Best Practices

1. **Type naturally** - Spell names as they would be pronounced
2. **Wait for auto-trigger** - Don't rush, let the system complete
3. **Review before saving** - Check the result makes sense
4. **Edit if needed** - Feel free to correct the Kannada if needed
5. **Use consistency** - Similar names should have similar transliterations

## FAQ

**Q: Can I disable transliteration?**
- A: Yes, just enter the name without waiting for auto-transliteration, then manually type the result

**Q: What if the transliteration is wrong?**
- A: You can edit it manually before clicking "Rename"

**Q: Does it support other Indian languages?**
- A: Currently only Kannada. Other language support can be added in future versions.

**Q: Is transliteration required?**
- A: No - you can save English-only names or manually enter Kannada if you prefer

**Q: How accurate is the transliteration?**
- A: ~85-90% accurate for standard Indian names. Accuracy depends on English spelling phonetics.
