(() => {
  const key = 'transmission-color-mode';
  const media = matchMedia('(prefers-color-scheme: dark)');
  const valid = value => ['system', 'dark', 'light'].includes(value) ? value : 'system';
  let mode = 'system';
  try { mode = valid(localStorage.getItem(key)); } catch {}
  // Retain existing dark rules and their cascade order, but make their media
  // conditions respond to the explicit preference instead of only the OS.
  const rules = [];
  function collect(list) {
    for (const rule of list) {
      if (rule instanceof CSSMediaRule && /prefers-color-scheme\s*:\s*dark/.test(rule.conditionText)) {
        rules.push({rule, query: rule.conditionText});
      }
      if (rule.cssRules) collect(rule.cssRules);
    }
  }
  for (const sheet of document.styleSheets) {
    try { collect(sheet.cssRules); } catch {}
  }
  function apply() {
    const dark = mode === 'dark' || (mode === 'system' && media.matches);
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    document.documentElement.dataset.colorMode = mode;
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
    for (const {rule, query} of rules) {
      rule.media.mediaText = query.replace(/\(prefers-color-scheme\s*:\s*dark\)/g, dark ? '(min-width: 0px)' : '(max-width: -1px)');
    }
    const toggle = document.getElementById('themeToggle');
    if (toggle) {
      toggle.querySelector('span').textContent = dark ? '深色' : '浅色';
      toggle.title = toggle.ariaLabel = dark ? '切换为浅色模式' : '切换为深色模式';
      toggle.querySelector('svg').innerHTML = dark
        ? '<path d="M20 14a8 8 0 0 1-10-10 8 8 0 1 0 10 10Z" fill="none" stroke="currentColor" stroke-width="1.6"/>'
        : '<circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>';
    }
    window.dispatchEvent(new CustomEvent('app-theme-change', {detail:{mode, theme:dark?'dark':'light'}}));
  }
  window.appTheme = {set(value) {mode=valid(value);try{localStorage.setItem(key,mode)}catch{}apply();}, get mode(){return mode;}};
  apply();
  media.addEventListener('change', apply);
  window.addEventListener('storage', event => {if(event.key===key || event.key===null){mode=valid(event.newValue);apply();}});
  document.addEventListener('DOMContentLoaded', () => {
    const help = document.querySelector('.help-document');
    if (help) {
      const toggle = document.createElement('button');
      toggle.id = 'themeToggle';
      toggle.className = 'theme-toggle';
      toggle.type = 'button';
      toggle.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"></svg><span></span>';
      help.after(toggle);
      toggle.addEventListener('click', () => window.appTheme.set(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'));
    }
    apply();
  });
})();
