# Project Task List

## Overview

This document tracks the Hello World real-time clock example. The project uses a
Java Spring Boot backend and an Angular frontend, with WebSocket updates sent once
per second.

## Goals

- Follow the project instructions and implement, test, and document the solution.
- Work as the project's senior developer and keep this tracker current.
- Provide a practical example of GitHub Actions configuration and usage.

## Project conventions

### Requirements

- Store application requirements in `requirements/functional/`.
- Name shared requirements `REQ-NNN-description.md`.
- Name application-specific requirements `EXAMPLE-REQ-NNN-description.md`.
- Store non-application-specific requirements in `requirements/non-functional/`.

### Repository layout

- `materials/` contains temporary assistive material supplied for the project.
- `documentation/` contains the HTML documentation. Keep `index.html` current,
  add focused subpages instead of one large page, and prefer Mermaid diagrams.
- `testing/` contains integration tests. Unit tests belong in their corresponding
  application modules.
- Backend applications use Java and Spring Boot.
- Frontend applications use Angular.

### Delivery workflow

For each new instruction set:

1. Analyze the task and create or update requirements under `requirements/`.
2. Update the relevant module README, such as `example-backend/README.md`.
3. Implement the change.
4. Add the advised unit and integration tests.
5. Update `start-dev-local.sh`, `stop-dev-local.sh`, `open-tabs.sh`, and
   `run-smoke-tests.sh` when needed.
6. Run the scripts and verify the relevant behavior.
7. Update the HTML documentation and add linked subpages when required.
8. Update this tracker with the observed evidence, blockers, and next action.

The default production deployment target is Azure, although AWS, GCP, and
on-premises deployments may also be documented.

## Status legend

- ⬜ Not started
- 🔧 In progress
- ✅ Complete and verified
- ⛔ Blocked

## Tasks

### 1. Requirement analysis

- [x] **1.1 ✅ Analyze the real-time clock feature.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: functional behavior, configuration, quality gates, scripts,
    documentation, and CI acceptance criteria defined on 2026-08-10.
- [x] **1.2 ✅ Create `EXAMPLE-REQ-001-hello-world.md`.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: requirement version `1.0.0` created and traced to tasks 1 through 7.

### 2. Backend implementation (Java Spring Boot)

- [x] **2.1 ✅ Set up the Spring Boot project structure.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **2.2 ✅ Implement the WebSocket configuration.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **2.3 ✅ Send clock updates every second.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **2.4 ✅ Add a REST endpoint for the initial page load.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **2.5 ✅ Configure the required Maven dependencies.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence for tasks 2.1–2.5: `mvn test` passed 3 tests with 0 failures and
    0 errors on 2026-08-10. A running Spring Boot instance returned health `UP`,
    a valid `GET /api/v1/clock` payload, and two real `/ws/clock` messages 1,079
    milliseconds apart. The live run required localhost bind/connect permission.

### 3. Frontend implementation (Angular)

- [x] **3.1 ✅ Set up the Angular project structure.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **3.2 ✅ Create a clock component for real-time updates.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **3.3 ✅ Implement the WebSocket connection to the backend.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **3.4 ✅ Display time in `HH:mm:ss` format.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **3.5 ✅ Handle WebSocket connection errors and reconnection.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence for tasks 3.1–3.5: Angular 22.1.1 production build succeeded and
    Vitest passed 5/5 tests on 2026-08-10. A headless Chrome session rendered a
    changing `HH:mm:ss` clock and `connected` state; after stopping the backend it
    rendered `reconnecting` plus an error, and returned to `connected` after the
    backend restarted.

### 4. Integration and testing

- [x] **4.1 ✅ Test WebSocket communication between backend and frontend.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **4.2 ✅ Verify that backend updates arrive once per second.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: real WebSocket messages arrived 1,079 milliseconds apart, within
    the required 750–1,500 millisecond local tolerance.
- [x] **4.3 ✅ Run backend and frontend unit tests.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: `mvn verify` passed 3/3 backend tests and `npm test` passed 5/5
    frontend tests on 2026-08-10.
- [x] **4.4 ✅ Run integration tests through `run-smoke-tests.sh`.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: the final smoke run started both applications, verified health,
    REST, frontend HTML, and two real WebSocket messages 815 milliseconds apart,
    then stopped both applications on 2026-08-10.

### 5. Documentation

- [x] **5.1 ✅ Add the clock example to `documentation/index.html`.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **5.2 ✅ Create focused documentation subpages.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **5.3 ✅ Add architecture and message-flow diagrams in Mermaid format.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
- [x] **5.4 ✅ Update the backend and frontend READMEs.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence for tasks 5.1–5.4: the documentation index and generated navigation
    link `clock-overview.html`, `clock-development.html`, and
    `github-actions.html`; architecture and sequence Mermaid diagrams are present;
    and the root and module READMEs document commands and configuration. Static
    link/file checks passed, and headless Chrome rendered the overview page,
    navigation, tables, and Mermaid diagrams on 2026-08-10.
- [x] **5.5 ✅ Remove obsolete documentation links and content.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: removed 27 links to absent review-tool, development-process, and
    AI-development pages from `documentation/index.html` and `nav-loader.js`.
    The retained four documentation routes returned HTTP 200, the local-link
    scan found zero missing targets, and headless Chrome rendered the cleaned
    landing page and four-item navigation on 2026-08-10.
- [x] **5.6 ✅ Document the intentionally inefficient clock design.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: the landing, architecture, and development pages explain that a
    production clock should advance locally in JavaScript/TypeScript, optionally
    synchronize with Java at a lower frequency, and that one-second WebSocket
    delivery exists only to demonstrate server push and reconnect behavior.
    Static content/link checks passed and headless Chrome rendered the caveat and
    surrounding Mermaid architecture diagram on 2026-08-10.

### 6. Local development scripts

- [x] **6.1 ✅ Update `start-dev-local.sh` to start both applications.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: the final smoke run used the script to build, launch, and wait for
    both applications successfully.
- [x] **6.2 ✅ Update `stop-dev-local.sh` to stop both applications.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: both tracked application PIDs were terminated by the final smoke
    run; a subsequent no-process run was safe and idempotent.
- [x] **6.3 ✅ Update `open-tabs.sh` to open the required browser tabs.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: `OPEN_BROWSER=false ./open-tabs.sh` printed the frontend, REST, and
    health URLs on 2026-08-10. macOS, Linux, and Windows launch paths are present;
    no GUI browser launch was performed.
- [x] **6.4 ✅ Verify all local-development scripts.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-001-hello-world.md`
  - Evidence: `bash -n` passed all four scripts; the full start/smoke/stop path
    passed; `OPEN_BROWSER=false ./open-tabs.sh` printed all three expected URLs;
    and ports 8080, 4200, 18080, and 14200 were free afterward. `shellcheck` is
    not installed.

### 7. GitHub Actions configuration

- [x] **7.1 ✅ Create CI/CD workflow files.**
  - Requirements: `requirements/functional/EXAMPLE-REQ-001-hello-world.md` and
    applicable files under `requirements/non-functional/`
- [x] **7.2 ✅ Configure automated testing.**
  - Requirements: `requirements/functional/EXAMPLE-REQ-001-hello-world.md` and
    applicable files under `requirements/non-functional/`
- [ ] **7.3 🔧 Configure deployment pipelines.**
  - Requirements: `requirements/functional/EXAMPLE-REQ-001-hello-world.md` and
    applicable files under `requirements/non-functional/`
- [x] **7.4 ✅ Document the GitHub Actions examples.**
  - Requirements: `requirements/functional/EXAMPLE-REQ-001-hello-world.md` and
    applicable files under `requirements/non-functional/`
  - Evidence for tasks 7.1, 7.2, and 7.4: workflow YAML validation passed;
    application CI covers Java 21 Maven verification and Node 26 audit, tests,
    build, and artifacts; documentation publishing examples are configured; and
    `documentation/github-actions.html` documents inputs and trust boundaries.
  - Current evidence for task 7.3: backend and frontend Docker images build and
    run locally as non-root services; container health/readiness, runtime frontend
    configuration, and real WebSocket messages passed. Both Helm charts lint and
    render. GitHub workflows configure amd64/arm64 GHCR publication, Pages/Azure
    documentation publishing, and manual OIDC-based ACR/AKS deployment.
  - Remaining verification: a GitHub-hosted multi-architecture publish and an
    Azure rollout require repository variables/secrets, federated Azure identity,
    ACR, AKS, and deployment URLs that are not available in this workspace.
- [x] **7.5 ✅ Implement Azure infrastructure with Terraform.**
  - Requirements: `requirements/functional/EXAMPLE-REQ-001-hello-world.md` and
    applicable files under `requirements/non-functional/`
  - Evidence: `terraform/` defines the resource group, ACR, monitored AKS with
    managed application routing, explicit control-plane and kubelet identities,
    scoped ACR access, and an environment-scoped GitHub OIDC deployment identity.
    Terraform 1.15.8 initialized AzureRM 4.81.0 and Random 3.9.0; recursive format
    checking and provider-schema validation passed, and the mocked secure-default
    plan test passed 1/1 on 2026-08-10. CI now runs the same checks, and headless
    Chrome rendered the Terraform workflow documentation. No Azure plan, apply,
    or hosted deployment was attempted without cloud credentials.

### 8. Automated offline code review

- [x] **8.1 ✅ Define the DeepSeek review and SMTP notification behavior.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Scope: run the supplied offline DeepSeek reviewer from GitHub Actions,
    optionally email its result through authenticated SMTP, prefer the push
    author's repository-visible email when usable, and support an explicitly
    selected fallback recipient.
- [x] **8.2 ✅ Integrate `code-review` with the GitHub Actions workflow.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Evidence: `.github/workflows/code-review.yaml` targets a trusted runner with
    the cumulative `self-hosted`, `code-review`, and `ollama` labels, runs Node
    tests, requires local DeepSeek for Java and TypeScript, and always uploads
    Markdown artifacts. Ruby parsed the YAML and verified its triggers, runner
    labels, job, and artifact step on 2026-08-24.
- [x] **8.3 ✅ Implement secure SMTP result delivery and recipient resolution.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Evidence: the Node notifier validates recipients, rejects line breaks and
    GitHub `noreply` addresses, supports an allowed-domain list, prefers push
    author metadata with a manual/configured fallback, and uses authenticated
    implicit TLS or STARTTLS. SMTP credentials are scoped to the review step.
- [ ] **8.4 🔧 Test and document local and hosted configuration.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Local evidence: `npm test --prefix code-review` passed 14 tests with 0
    failures and explicitly skipped the supplied sample-app suite because its
    `sample-apps/` fixtures were not supplied. Node syntax checks and
    `git diff --check` passed. A deterministic Java/TypeScript run generated
    three reports and skipped unconfigured SMTP cleanly.
  - Offline evidence: after temporarily starting local Ollama 0.31.1, the real
    required-provider run used installed `deepseek-coder:6.7b` for both Java and
    TypeScript and produced reports whose metadata says `Enabled (offline
    Ollama: deepseek-coder:6.7b)`. The aggregate advisory verdict was `DENIED`
    because DeepSeek incorrectly claimed that a no-argument GET controller needs
    `@RequestBody`; model verdicts are therefore documented as non-gating by
    default. The temporary Ollama service was stopped afterward.
  - Documentation evidence: root and reviewer READMEs, the GitHub Actions page,
    documentation navigation, landing page, and new `code-review.html` describe
    the runner, model, SMTP variables/secrets, recipient order, and verification
    boundary. Static file/link checks passed. After task 8.7, headless Chrome also
    rendered the updated page, navigation, Mermaid flow, email-content table,
    context warning, and OAuth configuration without visible overlap or clipping.
  - Remaining hosted verification: configure an online trusted self-hosted
    runner with both custom labels and the installed model, configure the Gmail
    OAuth refresh-token secret and a deliverable recipient, push or dispatch the
    workflow, confirm the uploaded artifact and received email, and inspect
    secret masking.
- [x] **8.5 ✅ Configure Gmail SMTP for automated review delivery.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Scope: use Gmail SMTP with sender/authentication identity
    `github-code-review@gmail.com`; keep its app password only in a GitHub Actions
    secret; update workflow, tests, and documentation; leave real delivery
    verification pending until the secret and Gmail account are configured.
  - Evidence: the workflow fixes `smtp.gmail.com:465`, implicit TLS, sender, and
    authentication identity, and reads only the password from
    `secrets.CODE_REVIEW_GMAIL_APP_PASSWORD`. Google-specific workflow tests and
    parsed-YAML assertions passed on 2026-08-24. The complete Node suite passed
    15 tests with 0 failures and 1 explicit missing-fixture skip; `git diff
    --check` passed. Requirements and documentation specify 2-Step Verification
    and a dedicated app password. No Gmail authentication or delivery was
    attempted without the secret.
  - Superseded authentication: task 8.6 replaces the app-password contract with
    Google OAuth 2.0 at the user's request; the Gmail host, port, sender, and TLS
    configuration remain applicable.
- [x] **8.6 ✅ Replace Gmail app-password authentication with OAuth 2.0.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Scope: consume existing GitHub secrets `SMTP_APPID` and `SMTP_SECRET` as the
    Google OAuth client ID and client secret, obtain short-lived access tokens,
    and authenticate to Gmail SMTP with SASL XOAUTH2.
  - Required additional credential: an unattended workflow cannot authorize a
    Gmail user with client credentials alone. Add the consent-derived offline
    refresh token as GitHub secret `SMTP_REFRESH_TOKEN`; do not misconfigure the
    OAuth client ID and secret as an SMTP username/password pair.
  - Evidence: the workflow consumes `secrets.SMTP_APPID`,
    `secrets.SMTP_SECRET`, and `secrets.SMTP_REFRESH_TOKEN`; the notifier exchanges
    them at Google's HTTPS token endpoint and uses the resulting short-lived
    access token with Gmail SASL XOAUTH2. Focused tests validate the token request,
    XOAUTH2 payload, required refresh token, and exact YAML secret names. The
    complete Node suite passed 18 tests with 0 failures and 1 explicit
    missing-fixture skip on 2026-08-24. Live token exchange and Gmail delivery
    remain unverified because `SMTP_REFRESH_TOKEN` has not been provided in the
    current context.
- [x] **8.7 ✅ Document the exact review-email payload and change context.**
  - Requirement: `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md`
  - Scope: update `documentation/` with the current subject/body fields, report
    size cap, push/manual trigger boundary, absence of PR/MR and commit context,
    OAuth prerequisites, and the distinction between static checks, browser
    rendering, and real Gmail delivery.
  - Evidence: `code-review.html` now contains an exact payload table, the
    200,000-character combined-report cap, a prominent list of omitted change
    identifiers, and the push/manual-only trigger boundary; `github-actions.html`
    summarizes the same limitation. Static HTML target checks, generated-nav
    route checks, and `git diff --check` passed on 2026-08-24. Headless Chrome
    rendered `code-review.html` at 1440x2200; visual inspection confirmed the
    sidebar, Mermaid diagram, payload table, warning, and OAuth sections render
    correctly. This is browser evidence only, not real Gmail delivery evidence.

## Requirements reference

- `requirements/functional/EXAMPLE-REQ-001-hello-world.md` — core real-time
  clock behavior and delivery acceptance criteria.
- `requirements/non-functional/REQ-009-multiarch-container-images.md` — amd64
  and arm64 publication requirements for both application images.
- `requirements/functional/EXAMPLE-REQ-002-automated-code-review.md` — offline
  DeepSeek review workflow and optional SMTP result notification.

## Current handoff

- Session instruction received 2026-08-24: record each new request in this
  tracker before beginning work.
- Intake status: **🔧 Task 8.7 documentation update complete;
  `SMTP_REFRESH_TOKEN`, hosted runner, and Gmail delivery verification remain
  under task 8.4**.
- Intake next action: configure and run the trusted GitHub self-hosted runner and
  SMTP integration described in task 8.4, then record the artifact and delivery
  evidence here.
- Active task: **8.4 — Verify the configured review and email path on GitHub and
  the selected SMTP server**.
- Active task: **7.3 — Verify the configured deployment pipelines on their hosted
  GitHub and Azure targets**.
- Last verified: Maven 3/3, Angular 5/5, production frontend build, npm audit with
  zero vulnerabilities, final local smoke (815 ms WebSocket interval), browser
  disconnect/reconnect behavior, both local container images, both Helm charts,
  workflow YAML, Terraform format/validate/test, cleaned documentation
  links/browser rendering, and script cleanup on 2026-08-10.
- Blocker: the workspace has no Azure provisioning identity or configured GitHub
  repository deployment context. Consequently, the Terraform plan/apply,
  published multi-architecture manifests, public DNS/TLS, and hosted rollouts
  cannot be truthfully verified locally.
- Next action: authenticate an identity authorized to provision resources and
  role assignments, review and apply the documented Terraform plan, copy its
  output variables to the GitHub `production` environment, configure public
  HTTPS/WSS URLs, dispatch the publishing/deployment workflows, and record the
  hosted evidence here.
