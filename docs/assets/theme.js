// Explicit Light/Dark toggle for the docs site -- same idea as the app's
// own toolbar button: always sets an explicit choice, overriding the
// system preference in either direction, persisted across pages/visits.
(function () {
  var KEY = 'sunk-cost-docs-theme';

  function systemPrefersDark() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  function currentTheme() {
    var saved = localStorage.getItem(KEY);
    if (saved === 'light' || saved === 'dark') return saved;
    return systemPrefersDark() ? 'dark' : 'light';
  }

  function updateButton(theme) {
    var btn = document.getElementById('theme-toggle');
    if (!btn) return;
    var next = theme === 'dark' ? 'light' : 'dark';
    btn.querySelector('.icon').textContent = theme === 'dark' ? '🌙' : '☀️';
    btn.querySelector('.label').textContent = theme === 'dark' ? 'Dark' : 'Light';
    btn.setAttribute('aria-label', 'Switch to ' + next + ' mode');
    btn.title = 'Switch to ' + next + ' mode';
  }

  function apply(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    updateButton(theme);
  }

  document.addEventListener('DOMContentLoaded', function () {
    apply(currentTheme());
    var btn = document.getElementById('theme-toggle');
    if (btn) {
      btn.addEventListener('click', function () {
        var next = currentTheme() === 'dark' ? 'light' : 'dark';
        try { localStorage.setItem(KEY, next); } catch (e) {}
        apply(next);
      });
    }
  });
})();
