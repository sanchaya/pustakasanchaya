// Kannada Auto-Transliteration
// Automatically transliterates English to Kannada as you type

function autoTransliterate(englishText, targetInputId) {
  if (!englishText || englishText.trim() === '') {
    document.getElementById(targetInputId).value = '';
    return;
  }

  var targetInput = document.getElementById(targetInputId);
  if (!targetInput) {
    console.error('Target input not found:', targetInputId);
    return;
  }

  // Show loading state
  targetInput.value = englishText + ' | Transliterating...';

  console.log('Transliterating: ' + englishText);

  // Try Aksharamukha API first (more reliable)
  transliterateWithAksharamukha(englishText, function(kannadaText) {
    if (kannadaText) {
      console.log('Aksharamukha transliteration successful: ' + kannadaText);
      targetInput.value = englishText + ' | ' + kannadaText;
    } else {
      console.log('Aksharamukha failed, trying Google');
      // Fallback to Google
      transliterateWithGoogle(englishText, function(googleResult) {
        if (googleResult) {
          console.log('Google transliteration successful: ' + googleResult);
          targetInput.value = englishText + ' | ' + googleResult;
        } else {
          console.warn('All transliteration methods failed');
          targetInput.value = englishText + ' | (transliteration unavailable)';
        }
      });
    }
  });
}

// Aksharamukha API transliteration
function transliterateWithAksharamukha(englishText, callback) {
  try {
    var apiUrl = 'https://www.aksharamukha.appspot.com/api/transliterate';
    var params = {
      'text': englishText,
      'to': 'kn_KN',
      'from': 'en_US'
    };

    var queryString = Object.keys(params).map(function(key) {
      return encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
    }).join('&');

    console.log('Calling Aksharamukha API for: ' + englishText);

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
      console.error('Aksharamukha error:', error);
      callback(null);
    });
  } catch (e) {
    console.error('Aksharamukha error:', e);
    callback(null);
  }
}

// Google transliteration fallback
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
