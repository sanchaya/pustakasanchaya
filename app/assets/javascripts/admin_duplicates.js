// Admin Books Duplicates
document.addEventListener('DOMContentLoaded', initDuplicates);
document.addEventListener('turbolinks:load', initDuplicates);

function initDuplicates() {
  // Only run on duplicates page
  if (!document.querySelector('.dupe-check')) return;
}

var keepers = {};

function toggleGroup(groupIdx, checked) {
  var checks = document.querySelectorAll('.dupe-check[data-group="' + groupIdx + '"]');
  checks.forEach(function(c) { c.checked = checked; });
}

function setKeeper(groupIdx, bookId) {
  keepers[groupIdx] = bookId;
  var rows = document.querySelectorAll('#group-' + groupIdx + ' tr[data-book-id]');
  rows.forEach(function(row) {
    var btn = row.querySelector('.keep-btn');
    var id = parseInt(row.getAttribute('data-book-id'));
    if (id === bookId) {
      btn.className = 'btn btn-sm btn-success keep-btn';
      btn.textContent = 'Keeping';
      row.style.background = '#e8f5e9';
    } else {
      btn.className = 'btn btn-sm btn-outline-primary keep-btn';
      btn.textContent = 'Keep';
      row.style.background = '';
    }
  });
}

function mergeGroup(groupIdx) {
  var keeperId = keepers[groupIdx];
  if (!keeperId) {
    alert('Please click "Keep" on the book you want to keep.');
    return;
  }

  var checks = document.querySelectorAll('.dupe-check[data-group="' + groupIdx + '"]:checked');
  var removeIds = [];
  checks.forEach(function(c) {
    var id = parseInt(c.value);
    if (id !== keeperId) removeIds.push(id);
  });

  if (removeIds.length === 0) {
    alert('Please check the duplicate books to remove.');
    return;
  }

  if (!confirm('Keep book #' + keeperId + ' and remove ' + removeIds.length + ' duplicate(s)?')) return;

  fetch(adminDuplicatesPaths.merge, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
    body: JSON.stringify({ keeper_id: keeperId, remove_ids: removeIds })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      var groupEl = document.getElementById('group-' + groupIdx);
      if (groupEl) groupEl.remove();
    } else {
      alert(data.error || 'Merge failed');
    }
  })
  .catch(function() { alert('Error merging books'); });
}