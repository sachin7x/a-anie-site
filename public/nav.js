// nav.js — client-side partial: injects brand + nav-toggle HTML into [data-nav-partial] stubs.
(function () {
  var NAV_HTML =
    '<a class="brand" href="/" aria-label="A-Anie — home">' +
      '<svg width="28" height="28" viewBox="0 0 32 32" aria-hidden="true" focusable="false">' +
        '<rect width="32" height="32" rx="8" fill="#131313"/>' +
        '<path d="M6 16h2v-4l3 6V12h2v8H11l-3-6v6H6z" fill="#FDFCE8"/>' +
      '</svg>' +
      '<span class="brand-name">A-Anie</span>' +
    '</a>' +
    '<button class="nav-toggle" id="navToggle" aria-label="Open menu" aria-expanded="false" aria-controls="navMenu">' +
      '<span class="nav-toggle-bar" aria-hidden="true"></span>' +
      '<span class="nav-toggle-bar" aria-hidden="true"></span>' +
      '<span class="nav-toggle-bar" aria-hidden="true"></span>' +
    '</button>';

  function inject() {
    var stubs = document.querySelectorAll('[data-nav-partial]');
    for (var i = 0; i < stubs.length; i++) {
      stubs[i].outerHTML = NAV_HTML;
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', inject);
  } else {
    inject();
  }
})();