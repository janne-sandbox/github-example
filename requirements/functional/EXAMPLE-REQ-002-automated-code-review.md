# EXAMPLE-REQ-002: Automated offline code review

## Metadata

- Requirement ID: `EXAMPLE-REQ-002`
- Version: `1.1.0`
- Status: Active
- Priority: High
- Applications: `code-review`, GitHub Actions

## Purpose

The repository shall run its supplied source-code reviewer in GitHub Actions
using an offline DeepSeek model served by Ollama. Review reports may be delivered
through authenticated SMTP to the person who pushed the reviewed change when a
deliverable address is available, with a configured recipient as fallback.

## Functional requirements

1. `.github/workflows/code-review.yaml` shall run on pushes to the trusted `main`
   branch and on manual dispatches.
2. The workflow shall run on a self-hosted runner that can reach Ollama at
   `127.0.0.1:11434`; it shall not send source code to a hosted model API.
3. The workflow shall review the Java backend and TypeScript frontend, generate
   Markdown reports, and upload them as a workflow artifact.
4. Offline DeepSeek availability shall be mandatory in the hosted workflow. A
   missing Ollama service or configured model shall fail the review rather than
   silently relabeling deterministic checks as an offline DeepSeek review.
5. SMTP notification shall be optional. When SMTP is configured, the email shall
   contain the aggregate verdict and generated report content.
6. On a push, recipient resolution shall prefer the push payload email, then the
   head-commit author email, then the checked-out commit author email.
7. A manual-dispatch address or repository-configured address shall be used when
   no deliverable push-author address can be resolved.
8. Invalid addresses, header-injection characters, and GitHub `noreply` addresses
   shall not be used as SMTP recipients.
9. An optional recipient-domain allowlist shall constrain both automatically
   resolved and configured recipient addresses.
10. Model findings and verdicts shall be reported as advisory by default. An
    explicit local option may turn a `DENIED` verdict into a failing process,
    while provider, invalid-response, test, and configured-delivery failures
    remain operational failures.
11. Documentation shall state the exact review-email subject and body content,
    combined-report size limit, workflow triggers, and any absent PR/commit/run
    identifiers so that advisory results are not mistaken for fully correlated
    change evidence.

## Security and configuration

1. The workflow shall use Gmail SMTP at `smtp.gmail.com:465` with implicit TLS.
2. The SMTP sender and authentication identity shall both be
   `github-code-review@gmail.com`.
3. The workflow shall obtain a short-lived Google OAuth access token using the
   client ID, client secret, and consent-derived offline refresh token stored in
   GitHub Actions secrets `SMTP_APPID`, `SMTP_SECRET`, and
   `SMTP_REFRESH_TOKEN`, respectively.
4. Gmail SMTP authentication shall use SASL XOAUTH2 for
   `github-code-review@gmail.com` with the short-lived access token and the
   `https://mail.google.com/` scope. OAuth client credentials shall never be sent
   as an SMTP username/password pair.
5. OAuth credentials and tokens shall not be committed, passed as command-line
   arguments, or written to reports. The normal Google Account password shall
   not be used.
6. Fallback recipient, allowed domains, and Ollama model name may be supplied as
   repository variables.
7. SMTP notification failure shall fail a configured notification attempt, while
   an entirely unconfigured SMTP integration shall leave review execution usable.
8. The workflow shall have read-only repository-content permission and shall not
   run the self-hosted review job for pull requests from untrusted forks.

## Verification

1. Node unit tests shall cover offline provider selection, mandatory-provider
   failure, recipient precedence, `noreply`/invalid address rejection, allowed
   domains, and safe email message construction.
2. A deterministic local run shall generate Java and TypeScript reports without
   SMTP configuration.
3. A live offline run shall confirm Ollama model use when the local model is
   available; otherwise the exact missing service/model condition shall remain a
   recorded hosted-run prerequisite.
4. Workflow syntax and documentation links shall be checked locally.
5. A real GitHub-hosted self-hosted-runner execution and real SMTP delivery remain
   hosted acceptance checks and shall not be inferred from unit tests.

## Traceability

- `CONTINUE.md`: tasks 8.1 through 8.4
- `.github/workflows/code-review.yaml`
- `code-review/run-review.js`
- `code-review/lib/notification.js`
- `code-review/tests/notification.test.js`
- `documentation/code-review.html`
