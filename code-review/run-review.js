#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const JavaAgent = require('./agents/java-agent');
const TypeScriptAgent = require('./agents/typescript-agent');
const ReactAgent = require('./agents/react-agent');
const CppAgent = require('./agents/cpp-agent');
const CsharpAgent = require('./agents/csharp-agent');
const RustAgent = require('./agents/rust-agent');
const {
  buildMessage,
  parseAllowedDomains,
  readGithubEvent,
  resolveNotificationRecipient,
  sendSmtpMessage
} = require('./lib/notification');

const AGENTS = {
  java: JavaAgent,
  typescript: TypeScriptAgent,
  react: ReactAgent,
  cpp: CppAgent,
  csharp: CsharpAgent,
  rust: RustAgent
};

function parseArguments(args) {
  return Object.fromEntries(args.map(argument => {
    const separator = argument.indexOf('=');
    const key = (separator < 0 ? argument : argument.slice(0, separator)).replace(/^--/, '');
    const value = separator < 0 ? 'true' : argument.slice(separator + 1);
    return [key, value];
  }));
}

function aggregateVerdict(results) {
  if (results.some(result => result.verdict === 'DENIED')) return 'DENIED';
  if (results.some(result => result.verdict === 'APPROVED WITH CHANGES')) return 'APPROVED WITH CHANGES';
  return 'APPROVED';
}

function gitAuthorEmail() {
  try {
    return execFileSync('git', ['log', '-1', '--format=%ae'], { encoding: 'utf8' }).trim();
  } catch {
    return '';
  }
}

function createSummary(results, verdict, timestamp) {
  const lines = [
    '# Automated Code Review Summary',
    '',
    `- Timestamp: ${new Date().toISOString()}`,
    `- Aggregate verdict: **${verdict}**`,
    `- Offline model: ${process.env.DEEPSEEK_OLLAMA_MODEL || 'deepseek-coder:6.7b'}`,
    ''
  ];
  for (const result of results) {
    lines.push(`- ${result.language}: **${result.verdict}** (${path.basename(result.reportPath)})`);
  }
  lines.push('');
  return { filename: `review-summary-${timestamp}.md`, content: lines.join('\n') };
}

async function notifyIfConfigured(summaryPath, reportPaths, verdict) {
  const smtpConfigured = Boolean(process.env.SMTP_HOST);
  const eventPayload = readGithubEvent(process.env.GITHUB_EVENT_PATH);
  const recipient = resolveNotificationRecipient({
    eventName: process.env.GITHUB_EVENT_NAME,
    eventPayload,
    gitEmail: gitAuthorEmail(),
    fallbackEmail: process.env.CODE_REVIEW_EMAIL_TO,
    allowedDomains: parseAllowedDomains(process.env.SMTP_ALLOWED_RECIPIENT_DOMAINS)
  });

  if (!smtpConfigured) {
    console.log('SMTP notification disabled: SMTP_HOST is not configured');
    return;
  }
  if (!recipient) {
    console.log('SMTP notification skipped: no deliverable recipient was resolved');
    return;
  }

  const reportBody = [summaryPath, ...reportPaths]
    .map(file => fs.readFileSync(file, 'utf8'))
    .join('\n\n---\n\n')
    .slice(0, 200000);
  const repository = process.env.GITHUB_REPOSITORY || path.basename(process.cwd());
  const message = buildMessage({
    from: process.env.SMTP_FROM,
    to: recipient.address,
    subject: `[${repository}] code review: ${verdict}`,
    body: `${reportBody}\n\nRecipient source: ${recipient.source}\n`
  });
  await sendSmtpMessage({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true',
    starttls: process.env.SMTP_STARTTLS !== 'false',
    authMode: process.env.SMTP_AUTH_MODE || 'password',
    username: process.env.SMTP_USERNAME,
    password: process.env.SMTP_PASSWORD,
    oauthClientId: process.env.SMTP_OAUTH_CLIENT_ID,
    oauthClientSecret: process.env.SMTP_OAUTH_CLIENT_SECRET,
    oauthRefreshToken: process.env.SMTP_OAUTH_REFRESH_TOKEN,
    from: process.env.SMTP_FROM,
    to: recipient.address
  }, message);
  console.log(`SMTP notification sent using recipient source: ${recipient.source}`);
}

async function main() {
  const params = parseArguments(process.argv.slice(2));
  const languages = (params.languages || 'java,typescript').split(',').map(value => value.trim()).filter(Boolean);
  const unknown = languages.filter(language => !AGENTS[language]);
  if (unknown.length) throw new Error(`Unsupported review language(s): ${unknown.join(', ')}`);

  const projectRoot = path.resolve(params['project-root'] || process.cwd());
  const requirementsDir = path.resolve(params['requirements-dir'] || path.join(projectRoot, 'requirements'));
  const outputDir = path.resolve(params['output-dir'] || path.join(projectRoot, 'code-review/results'));
  const timestamp = params.timestamp || new Date().toISOString().replace(/\D/g, '').slice(0, 12);
  const internet = params.internet === 'true';
  const deepseek = params.deepseek !== 'false';
  process.env.DEEPSEEK_REQUIRED = params['require-deepseek'] === 'true' ? 'true' : 'false';
  fs.mkdirSync(outputDir, { recursive: true });

  const results = [];
  for (const language of languages) {
    console.log(`\nRunning ${language} review...`);
    const Agent = AGENTS[language];
    const agent = new Agent(internet, deepseek);
    const result = await agent.run(projectRoot, requirementsDir, outputDir, timestamp);
    results.push({ language, ...result });
  }

  const verdict = aggregateVerdict(results);
  const summary = createSummary(results, verdict, timestamp);
  const summaryPath = path.join(outputDir, summary.filename);
  fs.writeFileSync(summaryPath, summary.content, 'utf8');
  await notifyIfConfigured(summaryPath, results.map(result => result.reportPath), verdict);
  console.log(`\nAggregate verdict: ${verdict}`);
  console.log(`Summary: ${summaryPath}`);
  if (params['fail-on'] === 'denied' && verdict === 'DENIED') process.exitCode = 2;
}

if (require.main === module) {
  main().catch(error => {
    console.error(`Code review failed: ${error.message}`);
    process.exit(1);
  });
}

module.exports = { aggregateVerdict, createSummary, parseArguments };
