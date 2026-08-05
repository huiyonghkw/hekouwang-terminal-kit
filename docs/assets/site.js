/* hekouwang-terminal-kit site — lang / progress / reveal
   Self-contained: no CDN. Pages set data-base on <html> for relative links if needed. */
(function () {
  var KEY = 'hkw-lang';
  var btnEn = document.getElementById('btn-en');
  var btnZh = document.getElementById('btn-zh');
  if (!btnEn || !btnZh) return;

  function set(lang, remember) {
    var zh = lang === 'zh';
    document.documentElement.classList.toggle('lang-zh', zh);
    document.documentElement.lang = zh ? 'zh-CN' : 'en';
    btnEn.setAttribute('aria-pressed', String(!zh));
    btnZh.setAttribute('aria-pressed', String(zh));
    if (remember) {
      try { localStorage.setItem(KEY, lang); } catch (e) {}
    }
  }

  var saved = null;
  try { saved = localStorage.getItem(KEY); } catch (e) {}
  set(saved || (/^zh/i.test(navigator.language || '') ? 'zh' : 'en'), false);
  btnEn.addEventListener('click', function () { set('en', true); });
  btnZh.addEventListener('click', function () { set('zh', true); });
})();

(function () {
  var bar = document.getElementById('prog');
  if (!bar) return;
  function tick() {
    var h = document.documentElement.scrollHeight - window.innerHeight;
    bar.style.width = (h > 0 ? (window.scrollY / h) * 100 : 0) + '%';
  }
  window.addEventListener('scroll', tick, { passive: true });
  window.addEventListener('resize', tick);
  tick();
})();

(function () {
  var els = document.querySelectorAll('.pre');
  if (!els.length) return;
  if (!('IntersectionObserver' in window)) {
    els.forEach(function (e) { e.classList.add('in'); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) {
        en.target.classList.add('in');
        io.unobserve(en.target);
      }
    });
  }, { rootMargin: '0px 0px -12% 0px' });
  els.forEach(function (e) { io.observe(e); });
  setTimeout(function () {
    els.forEach(function (e) { e.classList.add('in'); });
  }, 1800);
})();
