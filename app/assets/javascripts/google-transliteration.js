// Kannada Phonetic Transliteration
// Simple English to Kannada mapping based on phonetics

var kannadaMap = {
  'ka': 'ಕ', 'kha': 'ಖ', 'ga': 'ಗ', 'gha': 'ಘ', 'cha': 'ಚ',
  'chha': 'ಛ', 'ja': 'ಜ', 'jha': 'ಝ', 'nya': 'ಞ',
  'ta': 'ಟ', 'tha': 'ಠ', 'da': 'ಡ', 'dha': 'ಢ', 'na': 'ಣ',
  'pa': 'ಪ', 'pha': 'ಫ', 'ba': 'ಬ', 'bha': 'ಭ', 'ma': 'ಮ',
  'ya': 'ಯ', 'ra': 'ರ', 'la': 'ಲ', 'va': 'ವ', 'sha': 'ಶ',
  'shha': 'ಷ', 'sa': 'ಸ', 'ha': 'ಹ',
  
  'a': 'ಅ', 'aa': 'ಆ', 'i': 'ಇ', 'ee': 'ಈ', 'u': 'ಉ',
  'oo': 'ಊ', 'e': 'ಎ', 'ei': 'ಏ', 'o': 'ಒ', 'oi': 'ಓ',
  
  'k': 'ಕ್', 't': 'ಟ್', 'p': 'ಪ್', 'm': 'ಮ್', 'n': 'ನ್',
  'l': 'ಲ್', 'r': 'ರ್', 's': 'ಸ್', 'h': 'ಹ್'
};

function performTransliteration(englishText, callback) {
  console.log('Starting transliteration for:', englishText);
  
  // Simple phonetic transliteration
  var kannadaText = transliteratePhonetic(englishText);
  console.log('Transliteration result:', kannadaText);
  
  // Call callback immediately (no async needed)
  if (kannadaText && kannadaText.length > 0) {
    callback(kannadaText);
  } else {
    console.warn('Transliteration returned empty');
    callback(null);
  }
}

function transliteratePhonetic(text) {
  if (!text) return '';
  
  text = text.toLowerCase().trim();
  var result = '';
  var i = 0;
  
  while (i < text.length) {
    var matched = false;
    
    // Try to match multi-character sequences first (longest match)
    for (var len = 3; len >= 1; len--) {
      var substr = text.substr(i, len);
      if (kannadaMap[substr]) {
        result += kannadaMap[substr];
        i += len;
        matched = true;
        break;
      }
    }
    
    // If no match, keep the character as-is
    if (!matched) {
      result += text[i];
      i++;
    }
  }
  
  return result;
}
