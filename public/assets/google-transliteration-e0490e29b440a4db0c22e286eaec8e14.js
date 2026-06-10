// Kannada Phonetic Transliteration
// English to Kannada mapping based on phonetics

var kannadaMap = {
  // Consonant clusters (longer matches first)
  'shha': 'ಷ', 'chha': 'ಛ', 'jha': 'ಝ', 'dha': 'ಢ', 'tha': 'ಠ',
  'kha': 'ಖ', 'gha': 'ಘ', 'bha': 'ಭ', 'pha': 'ಫ',
  'cha': 'ಚ', 'nya': 'ಞ',
  
  // Single consonants (with inherent 'a' sound)
  'ka': 'ಕ', 'ga': 'ಗ', 'ja': 'ಜ', 'ta': 'ಟ', 'da': 'ಡ', 'na': 'ಣ',
  'pa': 'ಪ', 'ba': 'ಬ', 'ma': 'ಮ', 'ya': 'ಯ', 'ra': 'ರ', 'la': 'ಲ',
  'va': 'ವ', 'sa': 'ಸ', 'sha': 'ಶ', 'ha': 'ಹ',
  
  // Vowels  
  'aa': 'ಾ', 'ii': 'ೀ', 'uu': 'ೂ', 'ee': 'ೀ', 'oo': 'ೋ',
  'ai': 'ೈ', 'au': 'ೌ', 'ei': 'ೇ', 'oi': 'ೋ',
  
  'a': 'ಅ', 'i': 'ಇ', 'u': 'ಉ', 'e': 'ಎ', 'o': 'ಒ',
  
  // Common abbreviations
  'k': 'ಕ', 't': 'ಟ', 'p': 'ಪ', 'm': 'ಮ', 'n': 'ನ', 's': 'ಸ',
  'r': 'ರ', 'l': 'ಲ', 'v': 'ವ', 'h': 'ಹ', 'b': 'ಬ', 'd': 'ದ',
  'g': 'ಗ', 'j': 'ಜ', 'y': 'ಯ'
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
    for (var len = 4; len >= 1; len--) {
      if (i + len <= text.length) {
        var substr = text.substr(i, len);
        if (kannadaMap[substr]) {
          result += kannadaMap[substr];
          i += len;
          matched = true;
          break;
        }
      }
    }
    
    // If no match, keep the character as-is (spaces, numbers, punctuation)
    if (!matched) {
      result += text[i];
      i++;
    }
  }
  
  return result;
}
;
