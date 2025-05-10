const http = require('http');
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  console.log(`Received request: ${req.method} ${req.url}`);  // Log entry
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain'); 
  const msg = 'Hello Node!\n'
  res.end(msg);
});

server.listen(port, () => {
  console.log(`Server running on http://0.0.0.0:${port}/`);
});
