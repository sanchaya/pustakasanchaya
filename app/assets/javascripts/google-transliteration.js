// Kannada Transliteration Helper
// Automatic transliteration from English to Kannada
// Primary: Google Transliteration, Fallback: Aksharamukha API

function transliterateAndFill(englishText, targetInputId) {
  if (!englishText || englishText.trim() === '') {
    return;
  }

  var targetInput = document.getElementById(targetInputId);
  if (!targetInput) {
    console.error('Target input not found:', targetInputId);
    return;
  }

  // Show loading state
  targetInput.placeholder = 'Transliterating...';
  targetInput.disabled = true;

  console.log('Starting transliteration for: ' + englishText);

  // Try Google Transliteration first
  transliterateWithGoogle(englishText, function(kannadaText) {
    if (kannadaText) {
      console.log('Google transliteration successful: ' + kannadaText);
      targetInput.value = englishText + ' | ' + kannadaText;
      targetInput.placeholder = 'Bilingual name ready';
      targetInput.disabled = false;
      targetInput.focus();
    } else {
      console.log('Google transliteration failed, trying Aksharamukha API');
      // Fallback to Aksharamukha API
      transliterateWithAksharamukha(englishText, function(kannadaText) {
        if (kannadaText) {
          console.log('Aksharamukha transliteration successful: ' + kannadaText);
          targetInput.value = englishText + ' | ' + kannadaText;
          targetInput.placeholder = 'Bilingual name ready (via Aksharamukha)';
          targetInput.disabled = false;
          targetInput.focus();
        } else {
          console.warn('Both transliteration methods failed');
          // Just use English name
          targetInput.value = englishText;
          targetInput.placeholder = 'English only (transliteration unavailable)';
          targetInput.disabled = false;
          targetInput.focus();
        }
      });
    }
  });
}

// Google Transliteration (if available)
function transliterateWithGoogle(englishText, callback) {
  try {
    if (typeof google !== 'undefined' && google.inputtools) {
      google.inputtools.transliterate(
        [englishText],
        'en',
        'kn',
        function(result) {
          if (result && result.length > 0 && result[0].length > 0) {
            callback(result[0][0]);
          } else {
            callback(null);
          }
        }
      );
    } else {
      console.log('Google Input Tools not available');
      callback(null);
    }
  } catch (e) {
    console.error('Google transliteration error:', e);
    callback(null);
  }
}

// Aksharamukha API transliteration (fallback)
function transliterateWithAksharamukha(englishText, callback) {
  try {
    var apiUrl = 'https://www.aksharamukha.appspot.com/api/transliterate';
    var params = {
      'text': englishText,
      'to': 'kn_KN', // Kannada script
      'from': 'en_US' // English
    };

    // Build query string
    var queryString = Object.keys(params).map(function(key) {
      return encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
    }).join('&');

    console.log('Calling Aksharamukha API...');

    fetch(apiUrl + '?' + queryString, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(function(response) {
      if (!response.ok) {
        throw new Error('HTTP error! status: ' + response.status);
      }
      return response.json();
    })
    .then(function(data) {
      console.log('Aksharamukha response:', data);
      if (data && data.result) {
        callback(data.result);
      } else if (data && data.text) {
        callback(data.text);
      } else {
        callback(null);
      }
    })
    .catch(function(error) {
      console.error('Aksharamukha API error:', error);
      callback(null);
    });
  } catch (e) {
    console.error('Aksharamukha transliteration error:', e);
    callback(null);
  }
}

// Load Google Input Tools on page load
document.addEventListener('DOMContentLoaded', function() {
  // Optionally load Google Input Tools
  if (typeof google === 'undefined') {
    var script = document.createElement('script');
    script.src = 'https://www.google.com/inputtools/js/lang_kn.js';
    script.onerror = function() {
      console.log('Google Input Tools not available (OK - will use Aksharamukha)');
    };
    document.head.appendChild(script);
  }
});
