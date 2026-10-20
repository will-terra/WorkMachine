// Minimal service worker so Chrome/Edge offer "Install app".
// The app needs the local server anyway, so requests go straight to the network.
self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()))
self.addEventListener("fetch", () => {})
