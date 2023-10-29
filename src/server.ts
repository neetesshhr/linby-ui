import express from 'express';
import bodyParser from 'body-parser';
import { spawn } from 'child_process';
import { Server as WebSocketServer } from 'ws';

const app = express();
const port = 3000;

app.use(bodyParser.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

const server = app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});

// Set up WebSockets
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  ws.on('message', (message) => {
    const { pubkey, privkey, distro } = JSON.parse(message.toString());

    if (!pubkey || !privkey || !distro) {
      ws.send('Error: All fields (pubkey, privkey, distro) are required.');
      return;
    }

    const scriptProcess = spawn('sh', ['./setup.sh', '-k', privkey, '-d', distro, '-p', pubkey]);

    scriptProcess.stdout.on('data', (data) => {
      ws.send(data.toString());
    });

    scriptProcess.stderr.on('data', (data) => {
      ws.send(data.toString());
    });

    scriptProcess.on('close', (code) => {
      ws.send(`Child process exited with code ${code}`);
      ws.close();
    });
  });
});
