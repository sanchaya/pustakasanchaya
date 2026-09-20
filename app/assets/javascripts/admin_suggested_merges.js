// Admin Metadata - Suggested Merges
document.addEventListener('DOMContentLoaded', initSuggestedMerges);
document.addEventListener('turbolinks:load', initSuggestedMerges);

function initSuggestedMerges() {
  if (!document.getElementById('authors-tab')) return;
}

function applySuggestion(type, source, target, btn) {
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

  fetch(adminSuggestedMergesPaths.apply, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ type: type, source: source, target: target })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      var card = btn.closest('.suggestion-card');
      if (card) card.classList.add('dismissed');
      btn.innerHTML = '<i class="fas fa-check"></i> Merged';
      btn.classList.remove('btn-success');
      btn.classList.add('btn-secondary');
    } else {
      alert('Error: ' + (data.error || 'Unknown'));
      btn.disabled = false;
      btn.innerHTML = '<i class="fas fa-code-merge"></i> Merge';
    }
  })
  .catch(function(e) {
    alert('Error: ' + e.message);
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-code-merge"></i> Merge';
  });
}

function dismissSuggestion(type, source, target, btn) {
  var card = btn.closest('.suggestion-card');
  if (card) card.classList.add('dismissed');

  fetch(adminSuggestedMergesPaths.dismiss, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ type: type, source: source, target: target })
  })
  .then(function(r) { return r.json(); })
  .catch(function(e) { console.error(e); });
}