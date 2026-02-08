// Confirmation dialogs
function confirmDelete(name) {
  return confirm(name + 'を削除してもよろしいですか？この操作は元に戻せません。');
}

function confirmAction(message) {
  return confirm(message);
}

// Auto-dismiss alerts after 5 seconds
document.addEventListener('DOMContentLoaded', function() {
  var alerts = document.querySelectorAll('.alert');
  alerts.forEach(function(alert) {
    setTimeout(function() {
      alert.style.transition = 'opacity 0.3s ease-out';
      alert.style.opacity = '0';
      setTimeout(function() {
        alert.remove();
      }, 300);
    }, 5000);
  });
});

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
  // Ctrl/Cmd + K to focus search
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault();
    var searchInput = document.querySelector('input[name="search"]');
    if (searchInput) {
      searchInput.focus();
    }
  }
});

// Form validation feedback
document.addEventListener('DOMContentLoaded', function() {
  var forms = document.querySelectorAll('form');
  forms.forEach(function(form) {
    var requiredInputs = form.querySelectorAll('[required]');
    requiredInputs.forEach(function(input) {
      input.addEventListener('invalid', function() {
        this.classList.add('border-red-500');
      });
      input.addEventListener('input', function() {
        if (this.validity.valid) {
          this.classList.remove('border-red-500');
        }
      });
    });
  });
});
