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
  { name: 'McCarty', latitude: 29.645974, longitude: -82.344066, currentCount: 0, capacity: 12 },
  { name: 'Garage 5', latitude: 29.643310, longitude: -82.351471, currentCount: 0, capacity: 271 },
  { name: 'Garage 14', latitude: 29.642376, longitude: -82.351335, currentCount: 0, capacity: 2200 },
  { name: 'NPB', latitude: 29.641503, longitude: -82.351335, currentCount: 0, capacity: 12 },
  { name: 'Garage 13', latitude: 29.640541, longitude: -82.349703, currentCount: 0, capacity: 12 },
  { name: 'Garage 11', latitude: 29.636293, longitude: -82.368394, currentCount: 0, capacity: 900 },
  { name: 'Southwest 1', latitude: 29.637171, longitude: -82.368639, currentCount: 0, capacity: 274 },
  { name: 'Southwest Tennis', latitude: 29.638010, longitude: -82.367084, currentCount: 0, capacity: 100 },
  { name: 'Southwest 2', latitude: 29.637503, longitude: -82.367424, currentCount: 0, capacity: 148 },
  { name: 'Southwest 3', latitude: 29.637003, longitude: -82.367924, currentCount: 0, capacity: 158 },
  { name: 'Garage 7', latitude: 29.650583, longitude: -82.350972, currentCount: 12, capacity: 12 },
  { name: 'Stadium 1', latitude: 29.651728, longitude: -82.349180, currentCount: 0, capacity: 12 },
  { name: 'Stadium 2', latitude: 29.649024, longitude: -82.347825, currentCount: 0, capacity: 12 },
  { name: 'Stadium 3', latitude: 29.649791, longitude: -82.350006, currentCount: 0, capacity: 12 },
  { name: 'Tigert Parking', latitude: 29.649380, longitude: -82.340550, currentCount: 0, capacity: 12 }
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
