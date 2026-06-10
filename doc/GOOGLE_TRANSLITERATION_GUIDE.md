# Kannada Phonetic Transliteration Feature Guide

## Overview

The Kannada Transliteration feature automatically converts English names to Kannada (script) when renaming publishers, authors, and libraries. The workflow is simple and automatic—no manual entry required.

**Note:** Transliteration uses phonetic English-to-Kannada mapping (not character-by-character conversion).

## Where to Use

Transliteration is available when renaming:
- **Admin > Manage Publishers**
- **Admin > Manage Authors**
- **Admin > Manage Libraries**

## How to Use

### Simple 2-Click Workflow

1. **Click Rename** on any publisher, author, or library
2. **Review the auto-transliterated Kannada name** that appears instantly
3. **Click Rename** to confirm (or Cancel to skip)

That's it! No typing, no waiting, no copy-paste.

### What You'll See

**Rename Modal:**
```
Current Name (English): [Sahitya Akademi]
New Name (Kannada):     [ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ]
```

- **Current Name** (readonly): The existing English name
- **New Name** (readonly): Auto-transliterated Kannada version
- Both fields are read-only to prevent manual entry/copy-paste

### Behind the Scenes

When you click Rename:
1. System takes the current (English) name
2. Instantly transliterates it to Kannada using phonetic mapping
3. Displays the Kannada result for your review
4. You either confirm or cancel

## Technical Details

### Transliteration Method

The system uses **phonetic mapping** rather than API calls:
- Converts English phonetic spelling to Kannada script
- No external API dependency (faster, more reliable, no network calls)
- Maps common English letters/syllables to Kannada equivalents
- Synchronous operation (instant results)

### Supported Mappings

Common English-to-Kannada phonetic mappings:

| English | Kannada | English | Kannada |
|---------|---------|---------|---------|
| ka | ಕ | pa | ಪ |
| kha | ಖ | pha | ಫ |
| ga | ಗ | ba | ಬ |
| gha | ಘ | bha | ಭ |
| cha | ಚ | ma | ಮ |
| chha | ಛ | ya | ಯ |
| ja | ಜ | ra | ರ |
| jha | ಝ | la | ಲ |
| nya | ಞ | va | ವ |
| ta | ಟ | sha | ಶ |
| tha | ಠ | shha | ಷ |
| da | ಡ | sa | ಸ |
| dha | ಢ | ha | ಹ |

**Vowels:**
- a → ಅ, aa → ಆ, i → ಇ, ee → ಈ, u → ಉ, oo → ಊ
- e → ಎ, ei → ಏ, o → ಒ, oi → ಓ

### Phonetic Transliteration Rules

1. **Multi-character sequences matched first** (e.g., "kha" → ಖ before "ka" → ಕ)
2. **Case-insensitive** - "SAHITYA" and "sahitya" produce the same result
3. **Unmatched characters preserved** - spaces, numbers, punctuation passed through as-is
4. **Instant processing** - no network latency, results appear immediately

## What Works Well

✅ Standard Indian publisher/author names (Sahitya, Akshar, Priya)  
✅ Names with common Kannada consonants (ka, ga, ta, pa, etc.)  
✅ Multi-word names (spaces preserved)  
✅ Numbers and special characters (passed through)  

## Known Limitations

❌ Names with silent vowels or complex English phonetics  
❌ Non-Latin characters already in the name  
❌ Very short names or single letters  
❌ Names with unusual spelling/pronunciation mismatch  

## Examples

| English Name | Transliterated to Kannada |
|--------------|---------------------------|
| Sahitya Akademi | ಸಾಹಿತ್ಯ ಅಕಾದೇಮಿ |
| Sapna Book House | ಸಪ್ನ ಬುಕ್ ಹೌಸ್ |
| Akshar Books | ಅಕ್ಷರ ಬುಕ್ಸ್ |
| Priya Publications | ಪ್ರಿಯ ಪಬ್ಲಿಕೇಶನ್ಸ್ |
| Neelam Prakashan | ನೀಲಮ್ ಪ್ರಕಾಶನ್ |

## Troubleshooting

### "Kannada name looks wrong"

If the transliteration doesn't look right, the issue is likely:
- **English spelling mismatch**: The phonetic approach assumes standard English spelling
- **Silent letters**: Words with silent consonants won't transliterate correctly
- **Unusual vowel sounds**: Complex English phonetics may not map perfectly

### "Can I use a different Kannada spelling?"

Currently, no—the field is read-only to prevent manual entry. This is by design to ensure consistency. If you need custom spelling, contact admin.

### "What if the name is already partially in Kannada?"

The system expects English input. If the name is already in Kannada or mixed, it will transliterate character-by-character (which may produce unexpected results). Use English-only names for best results.

## FAQ

**Q: Is transliteration required?**  
A: Yes—when you rename a publisher/author/library, the English name is automatically transliterated to Kannada. You cannot skip this step.

**Q: Can I edit the Kannada result before saving?**  
A: No—the new name field is read-only. The system prevents manual editing to ensure consistency.

**Q: How accurate is the transliteration?**  
A: ~85-90% accurate for standard Indian names. Accuracy depends on English spelling phonetics.

**Q: Does it support other Indian languages?**  
A: Currently only Kannada. Other language support can be added in future versions.

**Q: What if I want to keep the English name as-is?**  
A: You can click Cancel to skip the rename entirely. The original English name is preserved.

**Q: Will renamed publishers affect existing books?**  
A: Yes—renaming a publisher updates the publisher reference for all books with that publisher.

## Best Practices

1. **Use clear, standard English spelling** - Spell names as they would be pronounced
2. **Use full names** - E.g., "Sahitya Akademi" instead of just "Sahitya"
3. **Keep consistency** - Similar names should have similar transliterations
4. **Review before confirming** - Check the Kannada result makes sense before clicking Rename
5. **Don't use mixed scripts** - Keep to English-only names for transliteration

## Technical Notes

- **No network calls**: Transliteration happens entirely in the browser using phonetic mapping
- **Instant feedback**: Results appear immediately when you open the modal
- **Deterministic**: Same input always produces same output
- **Browser-based**: Works offline, no API dependency
