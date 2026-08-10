# Example frontend

Angular frontend for `EXAMPLE-REQ-001`. It obtains an initial clock value over
HTTP and then displays live WebSocket updates in `HH:mm:ss` format.

## Local URL

- `http://localhost:4200`

## Prerequisites

- Node.js 26
- npm 11

## Commands

```bash
npm ci
npm start
npm test
npm run build
npm audit --audit-level=critical
```

## Runtime configuration

The development defaults target `http://localhost:8080` and
`ws://localhost:8080`. A deployment can override them before Angular starts by
replacing `public/config.js` with:

```javascript
window.__CLOCK_CONFIG__ = {
  restBaseUrl: 'https://api.example.com',
  webSocketBaseUrl: 'wss://api.example.com',
  reconnectDelayMs: 1000
};
```

The UI loads an initial REST value, opens a native WebSocket, displays local time
as `HH:mm:ss`, preserves the last valid value after malformed messages, and
reconnects after a bounded delay.

Implementation and verified command evidence are tracked in `../CONTINUE.md`.
