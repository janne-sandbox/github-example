const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildMessage,
  buildXoauth2Response,
  isDeliverableEmail,
  parseAllowedDomains,
  requestOAuthAccessToken,
  resolveNotificationRecipient
} = require('../lib/notification');

test('push payload email takes precedence over commit and fallback recipients', () => {
  const result = resolveNotificationRecipient({
    eventName: 'push',
    eventPayload: {
      pusher: { email: 'pusher@example.com' },
      head_commit: { author: { email: 'author@example.com' } }
    },
    gitEmail: 'git@example.com',
    fallbackEmail: 'fallback@example.com'
  });
  assert.deepEqual(result, { address: 'pusher@example.com', source: 'push payload' });
});

test('GitHub noreply and invalid addresses fall through to configured fallback', () => {
  const result = resolveNotificationRecipient({
    eventName: 'push',
    eventPayload: {
      pusher: { email: '123+actor@users.noreply.github.com' },
      head_commit: { author: { email: 'bad\naddress@example.com' } }
    },
    gitEmail: 'noreply@github.com',
    fallbackEmail: 'review@example.com'
  });
  assert.deepEqual(result, { address: 'review@example.com', source: 'configured fallback' });
});

test('recipient domain allowlist applies to automatic and fallback addresses', () => {
  const result = resolveNotificationRecipient({
    eventName: 'push',
    eventPayload: { pusher: { email: 'pusher@outside.example' } },
    gitEmail: 'developer@engineering.example.com',
    fallbackEmail: 'review@example.com',
    allowedDomains: parseAllowedDomains('example.com, engineering.example.com')
  });
  assert.deepEqual(result, { address: 'developer@engineering.example.com', source: 'checked-out commit' });
});

test('manual dispatch prefers its selected fallback over the checked-out author', () => {
  const result = resolveNotificationRecipient({
    eventName: 'workflow_dispatch',
    gitEmail: 'author@example.com',
    fallbackEmail: 'selected@example.com'
  });
  assert.deepEqual(result, { address: 'selected@example.com', source: 'configured fallback' });
});

test('email validation rejects header injection and GitHub noreply addresses', () => {
  assert.equal(isDeliverableEmail('person@example.com'), true);
  assert.equal(isDeliverableEmail('person@example.com\r\nBcc: attacker@example.com'), false);
  assert.equal(isDeliverableEmail('123+person@users.noreply.github.com'), false);
});

test('message builder normalizes body lines and rejects injected subjects', () => {
  const message = buildMessage({
    from: 'reviewer@example.com',
    to: 'developer@example.com',
    subject: 'Code review approved',
    body: 'Line one\nLine two'
  });
  assert.match(message, /Subject: Code review approved\r\n/);
  assert.match(message, /Line one\r\nLine two$/);
  assert.throws(() => buildMessage({
    from: 'reviewer@example.com',
    to: 'developer@example.com',
    subject: 'Review\r\nBcc: attacker@example.com',
    body: 'unsafe'
  }), /line break/);
});

test('XOAUTH2 response contains the Gmail user and bearer access token', () => {
  const encoded = buildXoauth2Response('github-code-review@gmail.com', 'access-token');
  const decoded = Buffer.from(encoded, 'base64').toString('utf8');
  assert.equal(decoded, 'user=github-code-review@gmail.com\x01auth=Bearer access-token\x01\x01');
});

test('OAuth access-token exchange uses client credentials and refresh token', async () => {
  let request;
  const accessToken = await requestOAuthAccessToken({
    clientId: 'client-id',
    clientSecret: 'client-secret',
    refreshToken: 'refresh-token'
  }, async (url, options) => {
    request = { url, options, body: Object.fromEntries(options.body.entries()) };
    return { ok: true, json: async () => ({ access_token: 'short-lived-token' }) };
  });

  assert.equal(accessToken, 'short-lived-token');
  assert.equal(request.url, 'https://oauth2.googleapis.com/token');
  assert.deepEqual(request.body, {
    client_id: 'client-id',
    client_secret: 'client-secret',
    refresh_token: 'refresh-token',
    grant_type: 'refresh_token'
  });
});

test('OAuth access-token exchange requires a refresh token', async () => {
  await assert.rejects(
    requestOAuthAccessToken({ clientId: 'client-id', clientSecret: 'client-secret' }),
    /refresh token are required/
  );
});
