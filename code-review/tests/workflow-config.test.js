const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const workflowPath = path.resolve(__dirname, '../../.github/workflows/code-review.yaml');

test('workflow uses fixed Gmail SMTP settings and OAuth secrets', () => {
  const workflow = fs.readFileSync(workflowPath, 'utf8');

  assert.match(workflow, /SMTP_HOST: smtp\.gmail\.com/);
  assert.match(workflow, /SMTP_PORT: '465'/);
  assert.match(workflow, /SMTP_SECURE: 'true'/);
  assert.match(workflow, /SMTP_FROM: github-code-review@gmail\.com/);
  assert.match(workflow, /SMTP_USERNAME: github-code-review@gmail\.com/);
  assert.match(workflow, /SMTP_AUTH_MODE: oauth2/);
  assert.match(workflow, /SMTP_OAUTH_CLIENT_ID: \$\{\{ secrets\.SMTP_APPID \}\}/);
  assert.match(workflow, /SMTP_OAUTH_CLIENT_SECRET: \$\{\{ secrets\.SMTP_SECRET \}\}/);
  assert.match(workflow, /SMTP_OAUTH_REFRESH_TOKEN: \$\{\{ secrets\.SMTP_REFRESH_TOKEN \}\}/);
  assert.doesNotMatch(workflow, /CODE_REVIEW_GMAIL_APP_PASSWORD/);
  assert.doesNotMatch(workflow, /CODE_REVIEW_SMTP_(?:HOST|USERNAME|PASSWORD)/);
});
