// Zero-dependency static file server for the viewer page.
// Run: node server.js   (serves this folder on port 8080)
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 8080;
const ROOT = __dirname;

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
};

http.createServer((req, res) => {
  let reqPath = req.url === '/' ? '/viewer.html' : req.url.split('?')[0];
  const filePath = path.join(ROOT, path.normalize(reqPath).replace(/^(\.\.[/\\])+/, ''));

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
}).listen(PORT, '0.0.0.0', () => {
  const interfaces = os.networkInterfaces();
  let localIP = 'localhost';
  
  for (const name of Object.keys(interfaces)) {
    for (const net of interfaces[name]) {
      const familyV4Value = typeof net.family === 'string' ? 'IPv4' : 4;
      if (net.family === familyV4Value && !net.internal) {
        localIP = net.address;
        break;
      }
    }
    if (localIP !== 'localhost') break;
  }

  console.log(`Viewer page: http://${localIP}:${PORT}/`);
});
