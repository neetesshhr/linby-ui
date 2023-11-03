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
    const { pubkey, privkey, distro, appname, servername, instancetype, deployregion, accesskey, secretkey } = JSON.parse(message.toString());

    if (!pubkey || !privkey || !distro || !appname || !servername || !instancetype || !deployregion || !accesskey || !secretkey) {
      ws.send('Error: All fields (pubkey, privkey, distro, appname, servername,instancetype, deployregion, accesskey , secretkey) are required.');
      return;
    }

    const scriptProcess = spawn('sh', ['./setup.sh', '-k', privkey, '-d', distro, '-p', pubkey, '-a', appname, '-i' , servername, '-t', instancetype, '-r', deployregion, '-s', accesskey, '-e', secretkey]);

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
