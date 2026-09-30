/* 共用 IndexedDB 佇列，供頁面(offline-queue.js)與 Service Worker 共同使用 */
(function (global) {
  const DB_NAME = 'oav-offline-db';
  const STORE = 'mutations';
  const DB_VERSION = 1;

  function openDB() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains(STORE)) {
          db.createObjectStore(STORE, { keyPath: 'id', autoIncrement: true });
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async function addToQueue(record) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      const req = store.add(Object.assign({ createdAt: Date.now() }, record));
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async function getAllQueue() {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readonly');
      const store = tx.objectStore(STORE);
      const req = store.getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async function removeFromQueue(id) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      const req = store.delete(id);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  // 依序重送佇列中的請求。伺服器回傳的 PK/唯一鍵衝突視為「已成功套用過」而非錯誤，
  // 讓斷線重連後的重複送出不會造成重複資料（由 SQL Server 的 PRIMARY KEY 約束把關）。
  async function flushQueue(onResult) {
    const items = await getAllQueue();
    items.sort((a, b) => a.id - b.id);
    for (const item of items) {
      try {
        const resp = await fetch(item.url, {
          method: item.method,
          headers: { 'Content-Type': 'application/json' },
          body: item.body ? JSON.stringify(item.body) : undefined,
        });
        if (resp.ok) {
          await removeFromQueue(item.id);
          onResult && onResult({ item, status: 'applied' });
        } else {
          const text = await resp.text().catch(() => '');
          const isDup = /PRIMARY KEY|UNIQUE|duplicate/i.test(text);
          await removeFromQueue(item.id);
          onResult && onResult({ item, status: isDup ? 'duplicate-ignored' : 'failed', detail: text });
        }
      } catch (err) {
        // 仍然離線，保留在佇列中，等下次觸發再試
        onResult && onResult({ item, status: 'offline' });
        break;
      }
    }
  }

  const api = { openDB, addToQueue, getAllQueue, removeFromQueue, flushQueue };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  global.OavQueue = api;
})(typeof self !== 'undefined' ? self : this);
