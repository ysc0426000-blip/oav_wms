importScripts('js/idb-queue.js');

const CACHE_NAME = 'oav-shell-v1';
const SHELL_FILES = [
  './',
  'index.html',
  'manifest.json',
  'css/style.css',
  'js/app.js',
  'js/grid.js',
  'js/offline-queue.js',
  'js/idb-queue.js',
  'icons/icon.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_FILES)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) => Promise.all(
      names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))
    )).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // API 一律走網路（資料要即時），失敗就讓呼叫端(offline-queue.js)自行處理佇列
  if (url.pathname.startsWith('/api/')) return;

  // App shell：cache-first，離線時仍可開啟主功能表
  if (event.request.method === 'GET') {
    event.respondWith(
      caches.match(event.request).then((cached) => cached || fetch(event.request).then((resp) => {
        const copy = resp.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        return resp;
      }).catch(() => cached))
    );
  }
});

// 斷線期間排入佇列的異動，連線恢復後由瀏覽器觸發 Background Sync 自動重送
self.addEventListener('sync', (event) => {
  if (event.tag === 'oav-sync') {
    event.waitUntil(OavQueue.flushQueue());
  }
});
