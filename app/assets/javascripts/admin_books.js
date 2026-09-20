// Admin Books page functionality
document.addEventListener('DOMContentLoaded', initBooksPage);
document.addEventListener('turbolinks:load', initBooksPage);

function initBooksPage() {
  // Only run on books page where these elements exist
  const selectAll = document.getElementById('selectAllBooks');
  if (!selectAll) return;

  // Edit book buttons
  document.querySelectorAll('.edit-book-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      editBook(this.dataset.bookId, this);
    });
  });

  // Bulk selection
  const checkboxes = document.querySelectorAll('.book-checkbox');
  const toolbar = document.getElementById('bulkActionsToolbar');
  const mergeBtn = document.getElementById('bulkMergeBtn');
  const clearBtn = document.getElementById('clearSelectionBtn');
  const selectedCount = document.getElementById('selectedCount');

  function updateToolbar() {
    const checked = document.querySelectorAll('.book-checkbox:checked');
    selectedCount.textContent = checked.length;
    mergeBtn.disabled = checked.length < 2;
    toolbar.style.display = checked.length > 0 ? 'block' : 'none';
  }

  if (selectAll) {
    selectAll.addEventListener('change', function() {
      checkboxes.forEach(cb => cb.checked = this.checked);
      updateToolbar();
    });
  }

  checkboxes.forEach(cb => cb.addEventListener('change', updateToolbar));

  if (clearBtn) {
    clearBtn.addEventListener('click', function() {
      checkboxes.forEach(cb => cb.checked = false);
      if (selectAll) selectAll.checked = false;
      updateToolbar();
    });
  }

  if (mergeBtn) {
    mergeBtn.addEventListener('click', openBulkMergeModal);
  }
}

function openBulkMergeModal() {
  const checked = document.querySelectorAll('.book-checkbox:checked');
  const count = checked.length;
  const list = document.getElementById('selectedBooksList');
  const countEl = document.getElementById('mergeSelectedCount');
  
  countEl.textContent = count;
  list.innerHTML = '';
  checked.forEach(cb => {
    const div = document.createElement('div');
    div.className = 'small mb-1';
    div.textContent = cb.dataset.title;
    list.appendChild(div);
  });

  document.getElementById('targetBookSelect').value = '';
  document.getElementById('includeCurrentPageOnly').checked = true;

  const modal = new bootstrap.Modal(document.getElementById('bulkMergeModal'));
  modal.show();
}

function performBulkMerge() {
  const checked = document.querySelectorAll('.book-checkbox:checked');
  const sourceIds = Array.from(checked).map(cb => cb.value);
  const targetId = document.getElementById('targetBookSelect').value;

  if (sourceIds.length < 2) {
    alert('Please select at least 2 books to merge');
    return;
  }
  if (!targetId) {
    alert('Please select a target book');
    return;
  }
  if (sourceIds.includes(targetId)) {
    alert('Target book cannot be in the source selection');
    return;
  }

  const btn = document.getElementById('confirmMergeBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Merging...';

  fetch(adminBooksPaths.mergeMultiple, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ source_ids: sourceIds, target_id: targetId })
  })
  .then(response => response.json())
  .then(data => {
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-compress-arrows-alt"></i> Merge Books';
    if (data.success) {
      alert(data.message);
      bootstrap.Modal.getInstance(document.getElementById('bulkMergeModal')).hide();
      location.reload();
    } else {
      alert('Error: ' + (data.error || 'Unknown error'));
    }
  })
  .catch(error => {
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-compress-arrows-alt"></i> Merge Books';
    alert('Error: ' + error.message);
  });
}

function editBook(bookId, button) {
  button.disabled = true;
  button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';

  fetch(adminBooksPaths.editBook.replace('BOOK_ID', bookId))
    .then(response => {
      if (!response.ok) {
        throw new Error('HTTP error! status: ' + response.status);
      }
      return response.json();
    })
    .then(data => {
      button.disabled = false;
      button.innerHTML = '<i class="fas fa-edit"></i> Edit';

      if (data.error) {
        alert('Error: ' + data.error);
        return;
      }

      renderEditForm(data);
      const modal = new bootstrap.Modal(document.getElementById('editModal'));
      modal.show();
    })
    .catch(error => {
      button.disabled = false;
      button.innerHTML = '<i class="fas fa-edit"></i> Edit';
      alert('Error loading book: ' + error.message);
    });
}

function escapeHtml(text) {
  return (text || '')
    .replace(/&/g, '&')
    .replace(/</g, '<')
    .replace(/>/g, '>')
    .replace(/"/g, '"')
    .replace(/'/g, '');
}

function renderEditForm(data) {
  const book = data.book;
  
  const html = `
    <form id="editForm">
      <div class="mb-3-wrapper">
        <label class="form-label">Title</label>
        <input type="text" class="form-control" data-field="name" value="${escapeHtml(book.name)}">
      </div>
      <div class="mb-3-wrapper">
        <label class="form-label">Author</label>
        <input type="text" class="form-control" data-field="author" value="${escapeHtml(book.author)}">
      </div>
      <div class="mb-3-wrapper">
        <label class="form-label">Publisher</label>
        <input type="text" class="form-control" data-field="publisher" value="${escapeHtml(book.publisher)}">
      </div>
      <div class="mb-3">
        <label class="form-label">Year</label>
        <input type="number" class="form-control" data-field="year" value="${escapeHtml(book.year)}">
      </div>
      <div class="alert alert-info">
        <small><strong>Source:</strong> ${escapeHtml(data.source_identifier)}</small>
      </div>
    </form>
  `;
  document.getElementById('editModalBody').innerHTML = html;
  document.getElementById('editForm').dataset.sourceId = data.source_identifier;
  document.getElementById('editForm').dataset.bookId = data.book.id;
}

function saveBookEdit() {
  const form = document.getElementById('editForm');
  const sourceId = form.dataset.sourceId;
  const bookId = form.dataset.bookId;
  const inputs = form.querySelectorAll('input');

  inputs.forEach(input => {
    const field = input.dataset.field;
    const value = input.value;

    fetch(adminBooksPaths.updateBook.replace('BOOK_ID', bookId), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        field: field,
        value: value
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        alert('Book updated successfully!');
        location.reload();
      } else {
        alert('Error: ' + (data.error || 'Unknown error'));
      }
    });
  });
}