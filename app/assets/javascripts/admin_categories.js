// Admin Metadata - Categories
document.addEventListener('DOMContentLoaded', initCategoriesMetadata);
document.addEventListener('turbolinks:load', initCategoriesMetadata);

function initCategoriesMetadata() {
  if (!document.getElementById('renameModal')) return;
}

let renameModal, mergeModal, mergeMultipleModal;

function closeModal(modal) {
  if (!modal) return;
  modal.classList.remove('show');
  modal.style.display = 'none';
  modal.setAttribute('aria-hidden', 'true');
  document.body.style.overflow = 'auto';
}

document.addEventListener('DOMContentLoaded', function() {
  renameModal = new bootstrap.Modal(document.getElementById('renameModal'), { keyboard: false });
  mergeModal = new bootstrap.Modal(document.getElementById('mergeModal'), { keyboard: false });
  mergeMultipleModal = new bootstrap.Modal(document.getElementById('mergeMultipleModal'), { keyboard: false });

  document.addEventListener('click', function(e) {
    if (e.target.closest('.rename-btn')) {
      e.preventDefault();
      var btn = e.target.closest('.rename-btn');
      var categoryName = btn.getAttribute('data-category-name');
      openRenameModal(categoryName);
    }
    
    if (e.target.closest('.merge-btn')) {
      e.preventDefault();
      var btn = e.target.closest('.merge-btn');
      var categoryName = btn.getAttribute('data-category-name');
      openMergeModal(categoryName);
    }
    
    if (e.target.closest('[data-bs-dismiss="modal"]')) {
      var modal = e.target.closest('.modal');
      if (modal) closeModal(modal);
    }
  });

  var selectAll = document.getElementById('selectAll');
  if (selectAll) {
    selectAll.addEventListener('change', function() {
      document.querySelectorAll('.select-item').forEach(function(cb) {
        cb.checked = this.checked;
      }.bind(this));
      updateSelectionToolbar();
    });
  });

  document.querySelectorAll('.select-item').forEach(function(cb) {
    cb.addEventListener('change', updateSelectionToolbar);
  });
});

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
  var selectAll = document.getElementById('selectAll');
  if (selectAll) selectAll.checked = false;
  updateSelectionToolbar();
}

function getSelectedNames() {
  return Array.from(document.querySelectorAll('.select-item:checked')).map(function(cb) { return cb.dataset.categoryName; });
}

function getSelectedIds() {
  return Array.from(document.querySelectorAll('.select-item:checked')).map(function(cb) { return cb.value; });
}

function openRenameModal(name) {
  document.getElementById('renameCategoryName').value = name;
  document.getElementById('renameNewName').value = '';
  document.getElementById('renameError').classList.add('d-none');
  document.getElementById('renameSuccess').classList.add('d-none');
  renameModal.show();
}

function openMergeModal(name) {
  document.getElementById('mergeCategoryName').value = name;
  document.getElementById('mergeTargetName').value = '';
  document.getElementById('mergeSimilarList').innerHTML = '';
  document.getElementById('mergeError').classList.add('d-none');
  document.getElementById('mergeSuccess').classList.add('d-none');
  mergeModal.show();
}

function submitRename() {
  var oldName = document.getElementById('renameCategoryName').value;
  var newName = document.getElementById('renameNewName').value.trim();
  if (!newName) { document.getElementById('renameError').textContent = 'Please enter a new name'; document.getElementById('renameError').classList.remove('d-none'); return; }
  fetch(adminCategoriesPaths.rename, {
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

function findSimilarCategories() {
  var name = document.getElementById('mergeTargetName').value;
  if (!name || name.trim().length < 2) { document.getElementById('mergeSimilarList').innerHTML = ''; return; }
  fetch(adminCategoriesPaths.findSimilar + '?name='+encodeURIComponent(name), {
    headers: {'X-CSRF-Token':document.querySelector('meta[name="csrf-token"]').content}
  }).then(function(r){return r.json()}).then(function(data){
    var list = document.getElementById('mergeSimilarList');
    if (!data.similar || data.similar.length===0) { list.innerHTML = '<small class="text-muted">No similar names found</small>'; return; }
    var html = '<div class="list-group">';
    data.similar.forEach(function(p){ html += '<button type="button" class="list-group-item list-group-item-action select-similar" data-name="'+p.name.replace(/"/g, '"')+'">'+p.name+' <small class="text-muted">['+p.occupation+']</small></button>'; });
    html += '</div>';
    list.innerHTML = html;
    list.querySelectorAll('.select-similar').forEach(function(b){ b.addEventListener('click',function(){document.getElementById('mergeTargetName').value=this.dataset.name;list.innerHTML='';}); });
  });
}

function submitMerge() {
  var oldName = document.getElementById('mergeCategoryName').value;
  var newName = document.getElementById('mergeTargetName').value.trim();
  if (!newName) { document.getElementById('mergeError').textContent = 'Please enter target name'; document.getElementById('mergeError').classList.remove('d-none'); return; }
  if (oldName===newName) { document.getElementById('mergeError').textContent = 'Must be different names'; document.getElementById('mergeError').classList.remove('d-none'); return; }
  fetch(adminCategoriesPaths.merge, {
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
  var ids = getSelectedIds();
  var names = getSelectedNames();
  var list = document.getElementById('mergeSourceList');
  list.innerHTML = '';
  names.forEach(function(n){var li=document.createElement('li');li.className='list-group-item';li.textContent=n;list.appendChild(li);});
  document.getElementById('mergeTargetNameMulti').value = '';
  document.getElementById('mergeMultipleError').classList.add('d-none');
  document.getElementById('mergeMultipleSuccess').classList.add('d-none');
  mergeMultipleModal.show();
}

function submitMergeMultiple() {
  var ids = getSelectedIds();
  var targetName = document.getElementById('mergeTargetNameMulti').value.trim();
  if (!targetName) { document.getElementById('mergeMultipleError').textContent = 'Enter target name'; document.getElementById('mergeMultipleError').classList.remove('d-none'); return; }
  fetch(adminCategoriesPaths.mergeMultiple, {
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