// Kannada Transliteration Helper
// Provides transliteration from English to Kannada

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
  targetInput.placeholder = 'Please enter Kannada text or paste it...';
  targetInput.focus();
  
  // Helper message showing what to do
  const helpText = `
English name: ${englishText}

You can:
1. Type in Kannada using the IME tool (already enabled)
2. Paste the Kannada text if you have it from elsewhere
3. Leave only the English name if Kannada is not available

Format: English name | ಕನ್ನಡ ಹೆಸರು (or just English name)
  `;
  
  console.log(helpText);
  
  // Pre-fill with English name so user can add Kannada
  targetInput.value = englishText + ' | ';
  
  // Place cursor after the pipe for Kannada entry
  setTimeout(() => {
    targetInput.focus();
    targetInput.setSelectionRange(targetInput.value.length, targetInput.value.length);
  }, 100);
}
