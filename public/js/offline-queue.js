/* 前端只負責：斷線時把異動請求存進 IndexedDB，連線恢復後自動重送。
   所有資料驗證/彙總計算都留在 SQL Server（觸發程序、檢視、約束）。 */
(function () {
  const pendingBadge = { count: 0 };
  const listeners = [];

  function onQueueChange(fn) { listeners.push(fn); }
  function notify() { listeners.forEach(fn => fn(pendingBadge.count)); }

  async function refreshPendingCount() {
    try {
      const items = await OavQueue.getAllQueue();
      pendingBadge.count = items.length;
    } catch (e) {
      pendingBadge.count = 0;
    }
    notify();
  }

  async function flush() {
    await OavQueue.flushQueue(() => {});
    await refreshPendingCount();
  }

  window.addEventListener('online', flush);
  window.addEventListener('load', () => {
    refreshPendingCount();
    if (navigator.onLine) flush();
  });

  async function mutate(method, url, body) {
    if (!navigator.onLine) {
      await OavQueue.addToQueue({ method, url, body });
      await refreshPendingCount();
      return { queued: true };
    }
    try {
      const resp = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });
      if (!resp.ok) {
        const text = await resp.text().catch(() => '');
        throw new Error(text || ('HTTP ' + resp.status));
      }
      return await resp.json().catch(() => ({ ok: true }));
    } catch (err) {
      // fetch 失敗（網路中斷）→ 放進佇列，等恢復連線後由 online 事件或 Background Sync 重送
      await OavQueue.addToQueue({ method, url, body });
      if ('serviceWorker' in navigator && 'SyncManager' in window) {
        try {
          const reg = await navigator.serviceWorker.ready;
          await reg.sync.register('oav-sync');
        } catch (e) { /* 部分瀏覽器不支援，靠 online 事件補上 */ }
      }
      await refreshPendingCount();
      return { queued: true, reason: err.message };
    }
  }

  window.api = {
    async get(url) {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(await resp.text().catch(() => 'request failed'));
      return resp.json();
    },
    post: (url, body) => mutate('POST', url, body),
    put: (url, body) => mutate('PUT', url, body),
    del: (url, body) => mutate('DELETE', url, body),
    onQueueChange,
    flush,
  };

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('service-worker.js').catch(() => {});
    });
  }
})();
