// Admin People page functionality (static parts)
document.addEventListener('DOMContentLoaded', initPeoplePage);
document.addEventListener('turbolinks:load', initPeoplePage);

function initPeoplePage() {
  // Only run on people page where these elements exist
  const selectAll = document.getElementById('selectAll');
  if (!selectAll) return;
  
  selectAll.addEventListener('change', function() {
    document.querySelectorAll('.select-item').forEach(function(cb) { cb.checked = this.checked; }.bind(this));
    updateSelectionToolbar();
  });
  document.querySelectorAll('.select-item').forEach(function(cb) { cb.addEventListener('change', updateSelectionToolbar); });
}

function updateSelectionToolbar() {
  var checked = document.querySelectorAll('.select-item:checked');
  var toolbar = document.getElementById('selectionToolbar');
  if (checked.length > 0) {
    document.getElementById('selectedCount').textContent = checked.length;
    toolbar.classList.remove('d-none');
  } else {
    toolbar.classList.add('d-none');
  }
}

function clearSelection() {
  document.querySelectorAll('.select-item').forEach(function(cb) { cb.checked = false; });
  document.getElementById('selectAll').checked = false;
  updateSelectionToolbar();
}

function getSelectedNames() {
  return Array.from(document.querySelectorAll('.select-item:checked')).map(function(cb) { return cb.dataset.name; });
}

function showModal(id) {
  var m = document.getElementById(id);
  m.classList.add('show'); m.style.display = 'block'; m.style.position = 'fixed';
  m.style.top = '0'; m.style.left = '0'; m.style.width = '100%'; m.style.height = '100%';
  m.style.zIndex = '99999'; m.style.backgroundColor = 'rgba(0,0,0,0.5)';
  document.body.style.overflow = 'hidden';
}

function hideModal(id) {
  var m = document.getElementById(id);
  m.classList.remove('show'); m.style.display = 'none';
  document.body.style.overflow = 'auto';
}

document.addEventListener('click', function(e) {
  if (e.target.closest('[data-bs-dismiss="modal"]')) hideModal(e.target.closest('.modal').id);
  if (e.target.closest('.rename-btn')) {
    var btn = e.target.closest('.rename-btn');
    document.getElementById('renameOldName').value = btn.dataset.personName;
    document.getElementById('renameNewName').value = '';
    document.getElementById('renameError').classList.add('d-none');
    document.getElementById('renameSuccess').classList.add('d-none');
    showModal('renameModal');
  }
  if (e.target.closest('.merge-btn')) {
    var btn = e.target.closest('.merge-btn');
    document.getElementById('mergeOldName').value = btn.dataset.personName;
    document.getElementById('mergeTargetName').value = '';
    document.getElementById('mergeSimilarList').innerHTML = '';
    document.getElementById('mergeError').classList.add('d-none');
    document.getElementById('mergeSuccess').classList.add('d-none');
    showModal('mergeModal');
  }
});

function escapeHtml(text) {
  return (text || '')
    .replace(/&/g, '&')
    .replace(/</g, '<')
    .replace(/>/g, '>')
    .replace(/"/g, '"')
    .replace(/'/g, '');
}

// URL paths - set from view via window.AdminPeoplePaths
var adminPeoplePaths = window.AdminPeoplePaths || {};

function submitRename() {
  var oldName = document.getElementById('renameOldName').value;
  var newName = document.getElementById('renameNewName').value.trim();
  if (!newName) { document.getElementById('renameError').textContent = 'Please enter a new name'; document.getElementById('renameError').classList.remove('d-none'); return; }
  fetch(adminPeoplePaths.rename, {
    method: 'POST', headers: {'Content-Type':'application/json','X-CSRF-Token':document.querySelector('meta[name="csrf-token"]').content},
    body: JSON.stringify({ old_name: oldName, new_name: newName })
  }).then(function(r){return r.json()}).then(function(data){
    if (data.success) {
      document.getElementById('renameSuccess').textContent = 'Renamed! Updated ' + data.affected_count + ' books';
      document.getElementById('renameSuccess').classList.remove('d-none');
      setTimeout(function(){location.reload()},1500);
    } else {
      document.getElementById('renameError').textContent = data.error; document.getElementById('renameError').classList.remove('d-none');
    }
  }).catch(function(e){document.getElementById('renameError').textContent='Error: '+e.message;document.getElementById('renameError').classList.remove('d-none')});
}

function findSimilarPeople() {
  var name = document.getElementById('mergeTargetName').value;
  if (!name || name.trim().length < 2) { document.getElementById('mergeSimilarList').innerHTML = ''; return; }
  fetch(adminPeoplePaths.findSimilar + '?name=' + encodeURIComponent(name), {
    headers: {'X-CSRF-Token':document.querySelector('meta[name="csrf-token"]').content}
  }).then(function(r){return r.json()}).then(function(data){
    var list = document.getElementById('mergeSimilarList');
    if (!data.similar || data.similar.length===0) { list.innerHTML = '<small class="text-muted">No similar names found</small>'; return; }
    var html = '<div class="list-group">';
    data.similar.forEach(function(p){ html += '<button type="button" class="list-group-item list-group-item-action select-similar" data-name="'+escapeHtml(p.name)+'">'+escapeHtml(p.name)+(p.name_kannada?' ('+escapeHtml(p.name_kannada)+')':'')+' <small class="text-muted">['+escapeHtml(p.occupation)+']</small></button>'; });
    html += '</div>';
    list.innerHTML = html;
    list.querySelectorAll('.select-similar').forEach(function(b){ b.addEventListener('click',function(){document.getElementById('mergeTargetName').value=this.dataset.name;list.innerHTML='';}); });
  });
}

function submitMerge() {
  var oldName = document.getElementById('mergeOldName').value;
  var newName = document.getElementById('mergeTargetName').value.trim();
  if (!newName) { document.getElementById('mergeError').textContent = 'Please enter target name'; document.getElementById('mergeError').classList.remove('d-none'); return; }
  if (oldName===newName) { document.getElementById('mergeError').textContent = 'Must be different names'; document.getElementById('mergeError').classList.remove('d-none'); return; }
  fetch(adminPeoplePaths.merge, {
    method: 'POST', headers: {'Content-Type':'application/json','X-CSRF-Token':document.querySelector('meta[name="csrf-token"]').content},
    body: JSON.stringify({ old_name: oldName, new_name: newName })
  }).then(function(r){return r.json()}).then(function(data){
    if (data.success) {
      document.getElementById('mergeSuccess').textContent = 'Merged! Updated ' + data.affected_count + ' books';
      document.getElementById('mergeSuccess').classList.remove('d-none');
      setTimeout(function(){location.reload()},1500);
    } else {
      document.getElementById('mergeError').textContent = data.error; document.getElementById('mergeError').classList.remove('d-none');
    }
  }).catch(function(e){document.getElementById('mergeError').textContent='Error: '+e.message;document.getElementById('mergeError').classList.remove('d-none')});
}

function openMergeMultipleModal() {
  var names = getSelectedNames();
  var list = document.getElementById('mergeSourceList');
  list.innerHTML = '';
  names.forEach(function(n){var li=document.createElement('li');li.className='list-group-item';li.textContent=n;list.appendChild(li);});
  document.getElementById('mergeTargetNameMulti').value = '';
  document.getElementById('mergeMultipleError').classList.add('d-none');
  document.getElementById('mergeMultipleSuccess').classList.add('d-none');
  showModal('mergeMultipleModal');
}

function submitMergeMultiple() {
  var ids = Array.from(document.querySelectorAll('.select-item:checked')).map(function(cb){return cb.value;});
  var targetName = document.getElementById('mergeTargetNameMulti').value.trim();
  if (!targetName) { document.getElementById('mergeMultipleError').textContent = 'Enter target name'; document.getElementById('mergeMultipleError').classList.remove('d-none'); return; }
  fetch(adminPeoplePaths.mergeMultiple, {
    method: 'POST', headers: {'Content-Type':'application/json','X-CSRF-Token':document.querySelector('meta[name="csrf-token"]').content},
    body: JSON.stringify({ source_ids: ids, target_name: targetName })
  }).then(function(r){return r.json()}).then(function(data){
    if (data.success) {
      document.getElementById('mergeMultipleSuccess').textContent = 'Merged '+data.merged_count+' people!';
      document.getElementById('mergeMultipleSuccess').classList.remove('d-none');
      setTimeout(function(){location.reload()},1500);
    } else {
      document.getElementById('mergeMultipleError').textContent = data.error||'Failed'; document.getElementById('mergeMultipleError').classList.remove('d-none');
    }
  }).catch(function(e){document.getElementById('mergeMultipleError').textContent='Error: '+e.message;document.getElementById('mergeMultipleError').classList.remove('d-none')});
}