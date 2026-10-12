// Service worker de la invitación: la deja instalable y visible sin conexión.
var VERSION = 'santi-v2';
var BASE = ['/', '/manifest.webmanifest', '/icons/icono-192.png', '/icons/icono-512.png', '/icons/apple-touch-icon.png'];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(VERSION).then(function (c) { return c.addAll(BASE); }).then(function () {
    return self.skipWaiting();
  }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (claves) {
    return Promise.all(claves.filter(function (k) { return k !== VERSION; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  var fuentes = url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';

  // Supabase, Google Maps y la lista de confirmados van siempre directo a la red.
  if (!fuentes && url.origin !== self.location.origin) return;
  if (url.pathname.indexOf('/admin') === 0) return;

  if (fuentes) {
    // Tipografías: primero la copia guardada, y se refresca por detrás.
    e.respondWith(caches.open(VERSION).then(function (c) {
      return c.match(req).then(function (guardada) {
        var red = fetch(req).then(function (r) { c.put(req, r.clone()); return r; }).catch(function () { return guardada; });
        return guardada || red;
      });
    }));
    return;
  }

  // La invitación: primero la red, para que los cambios se vean al momento; sin conexión, la copia guardada.
  e.respondWith(fetch(req).then(function (r) {
    if (r.ok) {
      var copia = r.clone();
      caches.open(VERSION).then(function (c) { c.put(req, copia); });
    }
    return r;
  }).catch(function () {
    return caches.match(req).then(function (guardada) {
      return guardada || (req.mode === 'navigate' ? caches.match('/') : Response.error());
    });
  }));
});
