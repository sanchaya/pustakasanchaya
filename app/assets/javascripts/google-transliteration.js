// Google Transliteration API Helper
// Provides transliteration from English to Kannada (and other languages)

class GoogleTransliterator {
  constructor() {
    this.language = 'kn'; // Kannada
    this.isLoaded = false;
    this.initGoogle();
  }

  initGoogle() {
    // Load Google Transliteration API
    const script = document.createElement('script');
    script.src = 'https://www.google.com/jsapi';
    script.onload = () => {
      google.load('language', '1', {
        callback: () => {
          this.isLoaded = true;
          console.log('Google Transliteration API loaded');
        }
      });
    };
    document.head.appendChild(script);
  }

  transliterate(englishText) {
    if (!englishText || englishText.trim() === '') {
      return '';
    }

    // Show loading state
    console.log('Transliterating: ' + englishText);

    // Prepare request
    const request = {
      text: englishText,
      language: [this.language]
    };

    return new Promise((resolve, reject) => {
      // Use Google's transliteration API
      if (google && google.language && google.language.transliterate) {
        google.language.transliterate([englishText], this.language, false, (result) => {
          if (result && result[0]) {
            const transliterated = result[0];
            resolve(transliterated);
          } else {
            reject('No transliteration available');
          }
        });
      } else {
        reject('Google Transliteration API not loaded');
      }
    });
  }
}

// Initialize global instance
let transliterator = null;

document.addEventListener('DOMContentLoaded', function() {
  // Initialize transliterator only if not already done
  if (!transliterator) {
    transliterator = new GoogleTransliterator();
  }
});

// Helper function to transliterate and fill input
function transliterateAndFill(englishText, targetInputId) {
  if (!englishText || englishText.trim() === '') {
    return;
  }

  const targetInput = document.getElementById(targetInputId);
  if (!targetInput) {
    console.error('Target input not found:', targetInputId);
    return;
  }

  // Show "transliterating..." feedback
  targetInput.placeholder = 'Transliterating...';
  targetInput.disabled = true;

  if (transliterator && transliterator.isLoaded) {
    transliterator.transliterate(englishText)
      .then((result) => {
        targetInput.value = englishText + ' | ' + result;
        targetInput.placeholder = 'Enter new name';
        targetInput.disabled = false;
      })
      .catch((error) => {
        console.error('Transliteration error:', error);
        targetInput.value = englishText;
        targetInput.placeholder = 'Transliteration failed - enter manually';
        targetInput.disabled = false;
      });
  } else {
    // API not loaded yet, use fallback
    console.warn('Transliterator not ready, using manual entry');
    targetInput.value = englishText;
    targetInput.placeholder = 'Enter new name';
    targetInput.disabled = false;
  }
}
