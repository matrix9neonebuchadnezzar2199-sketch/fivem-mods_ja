(function () {
  const app = document.getElementById('app');

  window.addEventListener('message', function (ev) {
    const data = ev.data;
    if (!data || typeof data !== 'object') {
      return;
    }
    if (data.type === 'open') {
      app.classList.remove('hidden');
    }
    if (data.type === 'close') {
      app.classList.add('hidden');
    }
  });
})();
