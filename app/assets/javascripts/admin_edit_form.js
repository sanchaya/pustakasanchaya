// Admin Books Edit Form
document.addEventListener('DOMContentLoaded', initEditForm);
document.addEventListener('turbolinks:load', initEditForm);

function initEditForm() {
  // Only run on edit form page
  if (!document.getElementById('contributorSearchInput')) return;
}

var selectedPersonId = null;
var bookId = window.AdminEditFormPaths?.bookId || null;

function toggleTranslationFields(checked) {
  var el = document.getElementById('translationFields');
  if (el) el.classList.toggle('d-none', !checked);
}

function searchContributors() {
  var q = document.getElementById('contributorSearchInput')?.value;
  if (!q || q.trim().length < 2) {
    var results = document.getElementById('contributorSearchResults');
    if (results) results.innerHTML = '';
    return;
  }
  fetch(adminEditFormPaths.findSimilar + '?q=' + encodeURIComponent(q), {
    headers: { 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    var results = document.getElementById('contributorSearchResults');
    if (!results) return;
    if (!data.similar || data.similar.length === 0) {
      results.innerHTML = '<small class="text-muted">No people found. <a href="' + adminEditFormPaths.peoplePath + '" target="_blank">Create a new person</a> first.</small>';
      return;
    }
    var html = '<div class="list-group" style="max-height: 250px; overflow-y: auto;">';
    data.similar.forEach(function(p) {
      html += '<button type="button" class="list-group-item list-group-item-action person-result" data-person-id="' + p.id + '" onclick="selectPerson(' + p.id + ', \'' + p.name.replace(/'/g, "\\'") + '\')">' + p.name + '</button>';
    });
    html += '</div>';
    results.innerHTML = html;
  });
}

function selectPerson(personId, personName) {
  selectedPersonId = personId;
  var input = document.getElementById('contributorSearchInput');
  if (input) input.value = personName;
  var results = document.getElementById('contributorSearchResults');
  if (results) results.innerHTML = '';
}

function submitAddContributor() {
  if (!selectedPersonId) {
    var err = document.getElementById('addContributorError');
    if (err) {
      err.textContent = 'Please select a person';
      err.classList.remove('d-none');
    }
    return;
  }
  var role = document.getElementById('newContributorRole')?.value;
  fetch(adminEditFormPaths.addContribution.replace(':id', selectedPersonId), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
    body: JSON.stringify({ book_id: bookId, role: role })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      location.reload();
    } else {
      var err = document.getElementById('addContributorError');
      if (err) {
        err.textContent = data.error || 'Failed to add contributor';
        err.classList.remove('d-none');
      }
    }
  })
  .catch(function() { var err = document.getElementById('addContributorError'); if (err) { err.textContent = 'Request failed'; err.classList.remove('d-none'); } });
}

function submitUpdateContributor(contribId) {
  var role = document.getElementById('contribRole_' + contribId)?.value;
  fetch(adminEditFormPaths.updateContribution.replace(':id', contribId), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
    body: JSON.stringify({ role: role })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      location.reload();
    } else {
      alert(data.error || 'Failed');
    }
  });
}

function removeContributor(contribId) {
  if (!confirm('Remove this contributor?')) return;
  fetch(adminEditFormPaths.removeContribution.replace(':id', contribId), {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      location.reload();
    } else {
      alert(data.error || 'Failed');
    }
  });
}