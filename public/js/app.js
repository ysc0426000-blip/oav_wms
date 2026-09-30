(function () {
  const appEl = document.getElementById('app');
  const pageTitle = document.getElementById('pageTitle');
  const backBtn = document.getElementById('backBtn');
  const statusDot = document.getElementById('statusDot');
  const statusText = document.getElementById('statusText');

  let meta = null;

  function setStatus(text, offline) {
    statusText.textContent = text;
    statusDot.classList.toggle('offline', !!offline);
  }

  async function refreshStatus() {
    if (!navigator.onLine) { setStatus('離線（將於恢復連線後自動重送）', true); return; }
    try {
      await api.get('/api/health');
      setStatus('連線正常', false);
    } catch (e) {
      setStatus('伺服器無回應', true);
    }
  }

  api.onQueueChange((count) => {
    if (count > 0) setStatus(`離線佇列中 ${count} 筆待送出`, true);
    else if (navigator.onLine) refreshStatus();
  });
  window.addEventListener('online', refreshStatus);
  window.addEventListener('offline', () => setStatus('離線（將於恢復連線後自動重送）', true));
  setInterval(refreshStatus, 20000);

  function showMenu() {
    pageTitle.textContent = 'OAV ERP 主功能表';
    backBtn.classList.remove('show');
    appEl.innerHTML = '';

    meta.menu.forEach((mod) => {
      const card = document.createElement('div');
      card.className = 'module-card';
      const title = document.createElement('div');
      title.className = 'module-title';
      title.textContent = mod.module;
      card.appendChild(title);

      mod.sections.forEach((sec) => {
        const block = document.createElement('div');
        block.className = 'section-block';
        const secTitle = document.createElement('div');
        secTitle.className = 'section-title';
        secTitle.textContent = sec.section;
        block.appendChild(secTitle);

        sec.items.forEach((item) => {
          const row = document.createElement('div');
          row.className = 'menu-item' + (item.type === 'undefined' ? ' disabled' : '');
          const label = document.createElement('span');
          label.textContent = item.label;
          row.appendChild(label);
          const arrow = document.createElement('span');
          arrow.className = 'arrow';
          arrow.textContent = item.type === 'undefined' ? '尚未定義' : '›';
          row.appendChild(arrow);
          if (item.type !== 'undefined') {
            row.addEventListener('click', () => openItem(item));
          }
          block.appendChild(row);
        });
        card.appendChild(block);
      });
      appEl.appendChild(card);
    });
  }

  function openItem(item) {
    pageTitle.textContent = item.label;
    backBtn.classList.add('show');
    appEl.innerHTML = '';
    if (item.type === 'lookup') {
      Grid.renderLookup(appEl, item.table, meta);
    } else if (item.type === 'doc') {
      Grid.renderDoc(appEl, item.header, item.detail, meta);
    } else if (item.type === 'report') {
      Grid.renderReport(appEl, item.view, meta);
    } else if (item.type === 'pivot') {
      Grid.renderPivot(appEl, item.proc, meta);
    }
  }

  backBtn.addEventListener('click', showMenu);

  async function init() {
    try {
      meta = await api.get('/api/meta');
      showMenu();
      refreshStatus();
    } catch (err) {
      appEl.innerHTML = `<div class="empty">無法載入系統結構，請確認連線後重新整理。<br>${err.message}</div>`;
    }
  }

  init();
})();
