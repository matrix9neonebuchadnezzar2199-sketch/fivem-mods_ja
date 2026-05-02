/**
 * 長いプレイヤー名・カード名のマーキー（overflow のみ）
 */
(function (global) {
  let resizeScheduled = false;
  let resizeTm = null;

  function run(root) {
    root = root || document;
    const targets = root.querySelectorAll('.player-name, .card-name');
    targets.forEach((el) => {
      const inner = el.querySelector('.player-name-inner, .card-name-inner');
      if (!inner) return;
      el.removeAttribute('data-overflow');
      void inner.offsetWidth;
      if (inner.scrollWidth > el.clientWidth + 1) {
        el.setAttribute('data-overflow', 'true');
      }
    });
  }

  function scheduleFull() {
    if (resizeScheduled) return;
    resizeScheduled = true;
    if (resizeTm) clearTimeout(resizeTm);
    resizeTm = setTimeout(() => {
      resizeScheduled = false;
      const app = document.getElementById('app');
      run(app || document);
    }, 150);
  }

  let resizeWired = false;
  function wireResizeOnce() {
    if (resizeWired) return;
    resizeWired = true;
    global.addEventListener('resize', scheduleFull);
  }

  global.applyMarqueeIfOverflow = function (root) {
    wireResizeOnce();
    run(root);
  };
})(window);
