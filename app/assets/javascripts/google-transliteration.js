// Simple Kannada Auto-Transliteration
// Transliterates as user types

function performTransliteration(englishText, callback) {
  console.log('Starting transliteration for:', englishText);
  
  // Try Aksharamukha API via JSONP
  var apiUrl = 'https://www.aksharamukha.appspot.com/api/transliterate?text=' + 
    encodeURIComponent(englishText) + '&from=en_US&to=kn_KN';
  
  console.log('Calling API:', apiUrl);
  
  // Use jQuery AJAX (available in Rails 4.2)
  jQuery.ajax({
    url: apiUrl,
    type: 'GET',
    dataType: 'json',
    timeout: 5000,
    success: function(data) {
      console.log('API response:', data);
      if (data && data.result) {
        callback(data.result);
      } else {
        console.warn('No result in API response');
        callback(null);
      }
    },
    error: function(xhr, status, error) {
      console.error('Aksharamukha API error:', status, error);
      callback(null);
    }
  });
}
