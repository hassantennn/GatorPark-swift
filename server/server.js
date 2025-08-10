const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(bodyParser.json());

let garages = [
  { name: 'Rawlings', latitude: 29.645255, longitude: -82.342954, currentCount: 0, capacity: 12 },
  { name: 'Reitz Garage', latitude: 29.645568, longitude: -82.348437, currentCount: 0, capacity: 12 },
  { name: 'McCarty', latitude: 29.645974, longitude: -82.344066, currentCount: 0, capacity: 12 }
];

app.get('/garages', (req, res) => {
  res.json(garages);
});

function broadcast(garage) {
  const msg = JSON.stringify(garage);
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
}

app.post('/garages/:name/:action', (req, res) => {
  const { name, action } = req.params;
  const garage = garages.find(g => g.name === name);
  if (!garage) {
    return res.status(404).end();
  }
  if (action === 'checkin' && garage.currentCount < garage.capacity) {
    garage.currentCount++;
  } else if (action === 'checkout' && garage.currentCount > 0) {
    garage.currentCount--;
  }
  broadcast(garage);
  res.json(garage);
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });
wss.on('connection', ws => {
  // No-op, updates will be pushed from broadcast
});

server.listen(3000, () => {
  console.log('Garage server listening on port 3000');
});
