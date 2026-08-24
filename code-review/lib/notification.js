const fs = require('node:fs');
const net = require('node:net');
const tls = require('node:tls');

function parseAllowedDomains(value) {
  return new Set(String(value || '')
    .split(',')
    .map(domain => domain.trim().toLowerCase())
    .filter(Boolean));
}

function isDeliverableEmail(value, allowedDomains = new Set()) {
  const address = String(value || '').trim();
  if (!address || address.length > 254 || /[\r\n]/.test(address)) return false;
  if (!/^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(address)) return false;
  if (/@(?:users\.)?noreply\.github\.com$/i.test(address) || /^noreply@github\.com$/i.test(address)) return false;

  const domain = address.slice(address.lastIndexOf('@') + 1).toLowerCase();
  return allowedDomains.size === 0 || allowedDomains.has(domain);
}

function resolveNotificationRecipient({ eventName, eventPayload = {}, gitEmail, fallbackEmail, allowedDomains }) {
  const domains = allowedDomains instanceof Set
    ? allowedDomains
    : parseAllowedDomains(allowedDomains);
  const pushCandidates = [
    ['push payload', eventPayload?.pusher?.email],
    ['head commit', eventPayload?.head_commit?.author?.email],
    ['checked-out commit', gitEmail],
    ['configured fallback', fallbackEmail]
  ];
  const candidates = eventName === 'push'
    ? pushCandidates
    : [['configured fallback', fallbackEmail], ['checked-out commit', gitEmail]];

  for (const [source, candidate] of candidates) {
    const address = String(candidate || '').trim();
    if (isDeliverableEmail(address, domains)) return { address, source };
  }
  return null;
}

function safeHeader(value, label) {
  const normalized = String(value || '').trim();
  if (!normalized || /[\r\n]/.test(normalized)) {
    throw new Error(`${label} is empty or contains a line break`);
  }
  return normalized;
}

function buildMessage({ from, to, subject, body, messageIdDomain }) {
  const safeFrom = safeHeader(from, 'SMTP sender');
  const safeTo = safeHeader(to, 'SMTP recipient');
  const safeSubject = safeHeader(subject, 'SMTP subject');
  const domain = safeHeader(messageIdDomain || safeFrom.split('@').pop(), 'message ID domain');
  const messageId = `<${Date.now()}.${Math.random().toString(16).slice(2)}@${domain}>`;
  const normalizedBody = String(body || '').replace(/\r?\n/g, '\r\n');

  return [
    `From: ${safeFrom}`,
    `To: ${safeTo}`,
    `Subject: ${safeSubject}`,
    `Date: ${new Date().toUTCString()}`,
    `Message-ID: ${messageId}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    '',
    normalizedBody
  ].join('\r\n');
}

function buildXoauth2Response(username, accessToken) {
  const user = safeHeader(username, 'SMTP OAuth username');
  const token = safeHeader(accessToken, 'SMTP OAuth access token');
  return Buffer.from(`user=${user}\x01auth=Bearer ${token}\x01\x01`, 'utf8').toString('base64');
}

async function requestOAuthAccessToken(config, fetchImpl = globalThis.fetch) {
  if (!config.clientId || !config.clientSecret || !config.refreshToken) {
    throw new Error('SMTP OAuth client ID, client secret, and refresh token are required');
  }
  if (typeof fetchImpl !== 'function') throw new Error('OAuth token transport is unavailable');

  const body = new URLSearchParams({
    client_id: config.clientId,
    client_secret: config.clientSecret,
    refresh_token: config.refreshToken,
    grant_type: 'refresh_token'
  });
  const response = await fetchImpl('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
    signal: AbortSignal.timeout(15000)
  });
  if (!response.ok) throw new Error(`Google OAuth token request failed with HTTP ${response.status}`);
  const payload = await response.json();
  if (!payload.access_token) throw new Error('Google OAuth token response did not include an access token');
  return payload.access_token;
}

function waitForConnection(socket, eventName) {
  return new Promise((resolve, reject) => {
    const onReady = () => { cleanup(); resolve(); };
    const onError = error => { cleanup(); reject(error); };
    const cleanup = () => {
      socket.off(eventName, onReady);
      socket.off('error', onError);
    };
    socket.once(eventName, onReady);
    socket.once('error', onError);
  });
}

function readResponse(socket, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    let response = '';
    const timer = setTimeout(() => finish(new Error('SMTP response timed out')), timeoutMs);
    const onData = chunk => {
      response += chunk.toString('utf8');
      const lines = response.split(/\r?\n/).filter(Boolean);
      const finalLine = lines.findLast(line => /^\d{3} /.test(line));
      if (finalLine) finish(null, { code: Number(finalLine.slice(0, 3)), response });
    };
    const onError = error => finish(error);
    const onClose = () => finish(new Error('SMTP connection closed unexpectedly'));
    const finish = (error, result) => {
      clearTimeout(timer);
      socket.off('data', onData);
      socket.off('error', onError);
      socket.off('close', onClose);
      if (error) reject(error); else resolve(result);
    };
    socket.on('data', onData);
    socket.once('error', onError);
    socket.once('close', onClose);
  });
}

async function command(socket, text, expectedCodes) {
  const responsePromise = readResponse(socket);
  socket.write(`${text}\r\n`);
  const result = await responsePromise;
  if (!expectedCodes.includes(result.code)) {
    throw new Error(`SMTP command failed with ${result.code}`);
  }
  return result;
}

async function sendSmtpMessage(config, message) {
  const host = safeHeader(config.host, 'SMTP host');
  const port = Number(config.port || (config.secure ? 465 : 587));
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('SMTP port is invalid');
  if (!config.username) throw new Error('SMTP username is required');
  const authMode = config.authMode || 'password';
  let accessToken;
  if (authMode === 'oauth2') {
    accessToken = await requestOAuthAccessToken({
      clientId: config.oauthClientId,
      clientSecret: config.oauthClientSecret,
      refreshToken: config.oauthRefreshToken
    });
  } else if (authMode === 'password') {
    if (!config.password) throw new Error('SMTP password is required');
  } else {
    throw new Error(`Unsupported SMTP authentication mode: ${authMode}`);
  }

  let socket = config.secure
    ? tls.connect({ host, port, servername: host, rejectUnauthorized: true })
    : net.connect({ host, port });
  await waitForConnection(socket, config.secure ? 'secureConnect' : 'connect');

  let greeting = await readResponse(socket);
  if (greeting.code !== 220) throw new Error(`SMTP greeting failed with ${greeting.code}`);
  await command(socket, `EHLO ${config.clientName || 'github-actions'}`, [250]);

  if (!config.secure) {
    if (config.starttls === false) throw new Error('Plain SMTP without STARTTLS is not permitted');
    await command(socket, 'STARTTLS', [220]);
    socket = tls.connect({ socket, servername: host, rejectUnauthorized: true });
    await waitForConnection(socket, 'secureConnect');
    await command(socket, `EHLO ${config.clientName || 'github-actions'}`, [250]);
  }

  if (authMode === 'oauth2') {
    const auth = buildXoauth2Response(config.username, accessToken);
    const result = await command(socket, `AUTH XOAUTH2 ${auth}`, [235, 334]);
    if (result.code === 334) {
      try { await command(socket, '', [535]); } catch { /* Gmail may close after a rejected token. */ }
      throw new Error('Gmail rejected SMTP XOAUTH2 authentication');
    }
  } else {
    const auth = Buffer.from(`\0${config.username}\0${config.password}`, 'utf8').toString('base64');
    await command(socket, `AUTH PLAIN ${auth}`, [235]);
  }
  await command(socket, `MAIL FROM:<${config.from}>`, [250]);
  await command(socket, `RCPT TO:<${config.to}>`, [250, 251]);
  await command(socket, 'DATA', [354]);

  const dotStuffed = message.replace(/\r\n\./g, '\r\n..');
  const deliveryPromise = readResponse(socket);
  socket.write(`${dotStuffed}\r\n.\r\n`);
  const delivery = await deliveryPromise;
  if (delivery.code !== 250) throw new Error(`SMTP delivery failed with ${delivery.code}`);
  try { await command(socket, 'QUIT', [221]); } finally { socket.end(); }
}

function readGithubEvent(eventPath) {
  if (!eventPath || !fs.existsSync(eventPath)) return {};
  return JSON.parse(fs.readFileSync(eventPath, 'utf8'));
}

module.exports = {
  buildMessage,
  buildXoauth2Response,
  isDeliverableEmail,
  parseAllowedDomains,
  readGithubEvent,
  requestOAuthAccessToken,
  resolveNotificationRecipient,
  sendSmtpMessage
};
