/**
 * VHP Panel - Minimal sunucu (health/ready ve placeholder UI).
 * Gerçek panel uygulaması bu yapı üzerine inşa edilir.
 */
const http = require('http');

const PORT = process.env.PORT || 3000;
const CONTROLLER_URL = process.env.VHP_CONTROLLER_URL || 'http://vhp-controller.vhp-control.svc.cluster.local:8080';

const server = http.createServer((req, res) => {
  const url = new URL(req.url || '/', `http://localhost:${PORT}`);

  if (url.pathname === '/health' || url.pathname === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }
  if (url.pathname === '/ready' || url.pathname === '/readyz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ready: true }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>VHP Panel</title></head>
<body>
  <h1>VHP Panel</h1>
  <p>Controller: ${CONTROLLER_URL}</p>
  <p>Panel çalışıyor. Gerçek arayüz bu altyapı üzerine eklenecek.</p>
</body>
</html>
  `);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`VHP Panel listening on port ${PORT}`);
});
