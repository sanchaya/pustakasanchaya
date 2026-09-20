// Admin Books Bulk Edit
(function() {
  document.addEventListener('DOMContentLoaded', initBulkEdit);
  document.addEventListener('turbolinks:load', initBulkEdit);

  function initBulkEdit() {
    if (!document.getElementById('field')) return;
  }

  function escapeHtml(text) {
    const map = {
      '&': '&',
      '<': '<',
      '>': '>',
      '"': '"',
      "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
  }

  function previewChanges() {
    const fieldEl = document.getElementById('field');
    const findValueEl = document.getElementById('findValue');
    const replaceValueEl = document.getElementById('replaceValue');
    const scopeEl = document.getElementById('scope');
    const field = fieldEl && fieldEl.value;
    const findValue = findValueEl && findValueEl.value;
    const replaceValue = replaceValueEl && replaceValueEl.value;
    const scope = scopeEl && scopeEl.value;

    if (!field || !findValue || !replaceValue) {
      alert('Please fill in all fields');
      return;
    }

    const container = document.getElementById('previewContainer');
    if (!container) return;
    
    container.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>';

    fetch(adminBulkEditPaths.preview, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        field: field,
        find_value: findValue,
        replace_value: replaceValue,
        scope: scope
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        container.innerHTML = '<div class="alert alert-danger">Error: ' + (data.error || 'Unknown error') + '</div>';
        return;
      }

      if (data.preview_count === 0) {
        container.innerHTML = '<div class="alert alert-warning"><i class="fas fa-search"></i> No matches found</div>';
        return;
      }

      let html = '<div class="alert alert-success">' +
        '<strong>Found ' + data.preview_count + ' matching book(s)</strong>' +
        (data.has_more ? '<br><small>(Showing first 50)</small>' : '') +
        '</div>';

      html += '<div class="table-responsive"><table class="table table-sm table-hover">';
      html += '<thead style="background: #f5f5f5;"><tr>';
      html += '<th>Title</th><th>Library</th><th>Old Value</th><th>New Value</th>';
      html += '</tr></thead><tbody>';

      data.preview_books.forEach(book => {
        html += '<tr>' +
          '<td><small><strong>' + escapeHtml(book.title) + '</strong></small></td>' +
          '<td><small><span class="badge bg-secondary">' + escapeHtml(book.library) + '</span></small></td>' +
          '<td><small><code style="background: #ffebee; padding: 2px 4px;">' + escapeHtml(book.old_value) + '</code></small></td>' +
          '<td><small><code style="background: #e8f5e9; padding: 2px 4px;">' + escapeHtml(book.new_value) + '</code></small></td>' +
          '</tr>';
      });

      html += '</tbody></table></div>';

      if (data.has_more) {
        html += '<small class="text-muted">... and more</small>';
      }

      container.innerHTML = html;
    })
    .catch(error => {
      container.innerHTML = '<div class="alert alert-danger">Error: ' + error + '</div>';
    });
  }

  function showWarning() {
    const fieldEl = document.getElementById('field');
    const findValueEl = document.getElementById('findValue');
    const replaceValueEl = document.getElementById('replaceValue');
    const field = fieldEl && fieldEl.value;
    const findValue = findValueEl && findValueEl.value;
    const replaceValue = replaceValueEl && replaceValueEl.value;

    if (!field || !findValue || !replaceValue) {
      alert('Please fill in all fields and preview first');
      return;
    }

    if (!confirm('Are you sure you want to update all matching books?\n\nField: ' + field + '\nFind: "' + findValue + '"\nReplace with: "' + replaceValue + '"\n\nThis action cannot be easily undone!')) {
      return;
    }

    applyChanges();
  }

  function applyChanges() {
    const fieldEl = document.getElementById('field');
    const findValueEl = document.getElementById('findValue');
    const replaceValueEl = document.getElementById('replaceValue');
    const scopeEl = document.getElementById('scope');
    const field = fieldEl && fieldEl.value;
    const findValue = findValueEl && findValueEl.value;
    const replaceValue = replaceValueEl && replaceValueEl.value;
    const scope = scopeEl && scopeEl.value;

    const container = document.getElementById('previewContainer');
    if (!container) return;
    
    container.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Applying changes...</span></div></div>';

    fetch(adminBulkEditPaths.apply, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        field: field,
        find_value: findValue,
        replace_value: replaceValue,
        scope: scope
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        container.innerHTML = '<div class="alert alert-danger">Error: ' + (data.error || 'Unknown error') + '</div>';
        return;
      }

      let html = '<div class="alert alert-success">' +
        '<strong><i class="fas fa-check-circle"></i> Successfully updated ' + data.affected_count + ' book(s)!</strong>' +
        '</div>';

      html += '<div class="table-responsive"><table class="table table-sm">';
      html += '<thead style="background: #f5f5f5;"><tr>';
      html += '<th>Title</th><th>Old Value</th><th>New Value</th>';
      html += '</tr></thead><tbody>';

      data.affected_books.forEach(book => {
        html += '<tr>' +
          '<td><small><strong>' + escapeHtml(book.title) + '</strong></small></td>' +
          '<td><small><code style="background: #ffebee; padding: 2px 4px;">' + escapeHtml(book.old_value) + '</code></small></td>' +
          '<td><small><code style="background: #e8f5e9; padding: 2px 4px;">' + escapeHtml(book.new_value) + '</code></small></td>' +
          '</tr>';
      });

      html += '</tbody></table></div>';
      html += '<div style="margin-top: 15px;"><a href="' + adminBulkEditPaths.back + '" class="btn btn-sm btn-primary">Back to Books</a></div>';

      container.innerHTML = html;

      var form = document.getElementById('bulkEditForm');
      if (form) form.reset();
    })
    .catch(error => {
      container.innerHTML = '<div class="alert alert-danger">Error: ' + error + '</div>';
    });
  }

  function escapeHtml(text) {
    const map = {
      '&': '&',
      '<': '<',
      '>': '>',
      '"': '"',
      "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
  }
})();