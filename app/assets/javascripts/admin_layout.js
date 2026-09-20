// Admin Layout JavaScript
(function() {
  function initAdminLayout() {
    $('.kan-ime').ime();
    $('.kan-ime').on('imeActivate', function() {
      $(this).closest('.input-group, .kan-ime-wrapper').addClass('ime-active');
    });

    // CSRF token setup for admin jQuery AJAX calls
    $.ajaxSetup({
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    });

    // Inline editing for metadata pages (authors, publishers, categories, libraries, stores)
    $(document).on('click', '.inline-edit', function(e) {
      var $el = $(this);
      if ($el.is('[contenteditable]')) return;
      var oldName = $el.data('old-name') || $el.text().trim();
      var url = $el.data('url');
      if (!url) return;
      $el.attr('contenteditable', 'true').focus();
      var range = document.createRange();
      range.selectNodeContents($el[0]);
      range.collapse(false);
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
      $el.on('blur.iedit keydown.iedit', function(e) {
        if (e.type === 'blur' || e.key === 'Enter') {
          e.preventDefault();
          var newName = $el.text().trim();
          $el.removeAttr('contenteditable').off('.iedit');
          if (newName && newName !== oldName) {
            $.ajax({
              url: url,
              method: 'POST',
              contentType: 'application/json',
              data: JSON.stringify({ old_name: oldName, new_name: newName }),
              success: function(res) {
                if (res.success) {
                  location.reload();
                } else {
                  alert('Error: ' + (res.error || 'Unknown'));
                  $el.text(oldName);
                }
              },
              error: function() {
                alert('Request failed');
                $el.text(oldName);
              }
            });
          }
        }
      });
    });
  }

  // Run on initial load and Turbolinks page loads
  $(document).ready(initAdminLayout);
  $(document).on('turbolinks:load', initAdminLayout);
})();