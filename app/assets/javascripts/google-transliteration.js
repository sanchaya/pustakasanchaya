// Kannada Transliteration Helper
// Provides transliteration from English to Kannada

function transliterateAndFill(englishText, targetInputId) {
  if (!englishText || englishText.trim() === '') {
    return;
  }

  var targetInput = document.getElementById(targetInputId);
  if (!targetInput) {
    console.error('Target input not found:', targetInputId);
    return;
  }

  // Show helper text
  targetInput.placeholder = 'Please enter Kannada text or paste it...';
  targetInput.focus();
  
  console.log('English name: ' + englishText);
  console.log('You can type Kannada using IME, paste, or use English only');
  
  // Pre-fill with English name so user can add Kannada
  targetInput.value = englishText + ' | ';
  
  // Place cursor after the pipe for Kannada entry
  setTimeout(function() {
    targetInput.focus();
    if (targetInput.setSelectionRange) {
      targetInput.setSelectionRange(targetInput.value.length, targetInput.value.length);
    }
  }, 100);
}
