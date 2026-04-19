/* Admin Panel Client-Side Helpers */

// API call helper — reads JWT from cookie automatically (browser sends it)
async function adminFetch(url, options = {}) {
  const defaults = { headers: { 'Content-Type': 'application/json' }, credentials: 'same-origin' };
  const res = await fetch(url, { ...defaults, ...options });
  if (res.redirected) { window.location.href = res.url; return null; }
  return res;
}

// Confirm action dialog
function confirmAction(message, formId) {
  if (confirm(message)) {
    document.getElementById(formId).submit();
  }
}

// Show/hide rejection modal
function showRejectModal(id, type) {
  const overlay = document.getElementById('reject-modal');
  if (!overlay) return;
  overlay.classList.add('show');
  document.getElementById('reject-item-id').value = id;
  document.getElementById('reject-type').value = type || '';
}

function hideRejectModal() {
  const overlay = document.getElementById('reject-modal');
  if (overlay) overlay.classList.remove('show');
}

// Submit rejection with reason
async function submitRejection() {
  const id = document.getElementById('reject-item-id').value;
  const type = document.getElementById('reject-type').value;
  const reason = document.getElementById('reject-reason').value;
  if (!reason.trim()) { alert('Please provide a rejection reason.'); return; }

  const endpoint = type === 'seller'
    ? `/admin/action/seller-applications/${id}/reject`
    : `/admin/action/items/${id}/reject`;

  const form = document.createElement('form');
  form.method = 'POST';
  form.action = endpoint;
  const input = document.createElement('input');
  input.type = 'hidden';
  input.name = 'rejectionReason';
  input.value = reason;
  form.appendChild(input);
  document.body.appendChild(form);
  form.submit();
}

// Approve action via POST form
function approveAction(id, type) {
  if (!confirm('Are you sure you want to approve this?')) return;
  const endpoint = type === 'seller'
    ? `/admin/action/seller-applications/${id}/approve`
    : `/admin/action/items/${id}/approve`;

  const form = document.createElement('form');
  form.method = 'POST';
  form.action = endpoint;
  document.body.appendChild(form);
  form.submit();
}

// Mobile sidebar toggle
function toggleSidebar() {
  const sidebar = document.querySelector('.sidebar');
  if (sidebar) sidebar.classList.toggle('open');
}

// Close sidebar on outside click (mobile)
document.addEventListener('click', (e) => {
  const sidebar = document.querySelector('.sidebar');
  const toggle = document.querySelector('.menu-toggle');
  if (sidebar && sidebar.classList.contains('open') && !sidebar.contains(e.target) && !toggle.contains(e.target)) {
    sidebar.classList.remove('open');
  }
});
