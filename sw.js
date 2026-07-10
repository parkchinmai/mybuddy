const CACHE = 'travel-buddy-v3';
const APP_URLS = [
  '.',
  'index.html',
  'manifest.json',
  'icon.svg',
  'icon-192.png',
  'icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(APP_URLS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => k !== CACHE).map(k => caches.delete(k))
    ))
  );
});

self.addEventListener('fetch', event => {
  const url = event.request.url;
  // App files: cache first
  if (url.endsWith('/') || url.includes('index.html') || url.includes('manifest.json') || url.includes('icon.svg')) {
    event.respondWith(
      caches.match(event.request).then(match => match || fetch(event.request))
    );
    return;
  }
  // CDN resources: network first, cache on success
  if (url.includes('fonts.googleapis.com') || url.includes('fonts.gstatic.com') ||
      url.includes('unpkg.com') || url.includes('esm.sh') ||
      url.includes('googleapis.com') || url.includes('gstatic.com')) {
    event.respondWith(
      fetch(event.request).then(response => {
        const clone = response.clone();
        caches.open(CACHE).then(cache => cache.put(event.request, clone));
        return response;
      }).catch(() => caches.match(event.request))
    );
    return;
  }
  // Everything else: network only
  event.respondWith(fetch(event.request));
});
