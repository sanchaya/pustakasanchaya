// Simple Kannada Auto-Transliteration
// Transliterates as user types

function performTransliteration(englishText, callback) {
  console.log('Starting transliteration for:', englishText);
  
  // Call local Rails endpoint (which proxies to Aksharamukha API)
  var endpoint = '/admin/transliterate';
  
  console.log('Calling endpoint:', endpoint);
  
  // Use jQuery AJAX (available in Rails 4.2)
  jQuery.ajax({
    url: endpoint,
    type: 'POST',
    dataType: 'json',
    data: { text: englishText },
    timeout: 5000,
    success: function(data) {
      console.log('API response:', data);
      if (data && data.result) {
        callback(data.result);
      } else {
        console.warn('No result in API response:', data);
        callback(null);
      }
    },
    error: function(xhr, status, error) {
      console.error('Transliteration error:', status, error);
      console.error('Response:', xhr.responseText);
      callback(null);
    }
  });
}
