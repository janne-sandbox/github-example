# Offline code review

This directory runs deterministic source checks together with an optional local
DeepSeek model served by Ollama. The GitHub workflow requires DeepSeek and uses a
self-hosted runner labelled `code-review` and `ollama`; source code is not sent to
the hosted DeepSeek API.

## Local review

Install Node.js 20 or newer, Ollama, and the configured model, then run:

```bash
ollama pull deepseek-coder:6.7b
node code-review/run-review.js \
  --languages=java,typescript \
  --deepseek=true \
  --internet=false \
  --require-deepseek=true
```

Use `--require-deepseek=false` for deterministic fallback during local tooling
development. Reports are written to `code-review/results/`, which is ignored by
Git. Review findings are advisory by default because model output requires human
validation; add `--fail-on=denied` only when a repository deliberately chooses to
make a `DENIED` verdict a quality gate. Provider, test, response-format, and
configured SMTP failures remain operational workflow failures.

## GitHub runner and Gmail SMTP

Register a trusted self-hosted runner with the labels `code-review` and `ollama`.
Ollama must listen on `127.0.0.1:11434`, and the value of the optional repository
variable `DEEPSEEK_OLLAMA_MODEL` must already be installed on that runner.

The workflow uses Gmail SMTP with implicit TLS and OAuth 2.0. The registered
Google OAuth client ID and client secret are read from `SMTP_APPID` and
`SMTP_SECRET`. Gmail SMTP also needs an access token for the mailbox user, so
authorize `github-code-review@gmail.com` once with offline access and the
`https://mail.google.com/` scope, then store the resulting refresh token as
`SMTP_REFRESH_TOKEN`. Client ID and client secret alone cannot authorize SMTP.

| Kind | Name | Purpose |
| --- | --- | --- |
| Workflow | SMTP host | `smtp.gmail.com` |
| Workflow | SMTP port | `465` |
| Workflow | Sender and username | `github-code-review@gmail.com` |
| Secret | `SMTP_APPID` | Google OAuth client ID |
| Secret | `SMTP_SECRET` | Google OAuth client secret |
| Secret | `SMTP_REFRESH_TOKEN` | Consent-derived offline refresh token |
| Variable | `CODE_REVIEW_EMAIL_TO` | Fallback recipient |
| Variable | `CODE_REVIEW_EMAIL_DOMAINS` | Optional comma-separated allowed domains |

For push events the tool prefers the push payload email, then the head-commit
author and checked-out Git author. Invalid and GitHub `noreply` addresses are
skipped. A manual workflow dispatch may provide a one-run fallback address.

At runtime the notifier exchanges those three credentials for a short-lived
access token and authenticates to SMTP using SASL XOAUTH2. Run unit tests with
`npm test` from this directory. A real Gmail delivery requires all three OAuth
secrets and the external runner.
