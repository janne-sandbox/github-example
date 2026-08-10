# EXAMPLE-REQ-001: Real-time Hello World clock

## Metadata

- Requirement ID: `EXAMPLE-REQ-001`
- Version: `1.1.0`
- Status: Active
- Priority: High
- Applications: `example-backend`, `example-frontend`

## Purpose

The example shall demonstrate a Java Spring Boot backend sending a live clock to
an Angular frontend over a WebSocket connection. It shall also demonstrate the
project's requirements-driven workflow, local scripts, automated tests,
documentation, and GitHub Actions configuration.

## Functional requirements

### Backend

1. The backend shall expose `GET /api/v1/clock` for initial page loading.
2. The REST response shall contain:
   - `text`: `Hello World, clock is <timestamp>`;
   - `timestamp`: an ISO 8601 timestamp with an offset.
3. The backend shall accept WebSocket connections at `/ws/clock`.
4. It shall send the current clock payload immediately after a connection opens.
5. It shall broadcast a new clock payload every second while clients are
   connected.
6. One failed or closed client session shall not prevent updates to other clients.

### Frontend

1. The frontend shall load its initial value from `GET /api/v1/clock`.
2. It shall then use `/ws/clock` for real-time updates without page refreshes or
   polling.
3. It shall show the received time in `HH:mm:ss` format.
4. It shall expose connection state to the user.
5. It shall recover from a dropped WebSocket connection by retrying with a bounded
   delay and shall cancel retries when the component is destroyed.
6. Invalid messages shall produce a visible error without replacing the last
   valid clock value.

## Configuration

- The backend development port shall default to `8080`.
- The frontend development port shall default to `4200`.
- The frontend shall support configurable REST and WebSocket base URLs.
- Local cross-origin access shall be limited to the configured frontend origin.

## Quality and verification

1. Backend unit or slice tests shall verify the REST payload and WebSocket clock
   message serialization.
2. Frontend unit tests shall verify clock rendering, connection-state behavior,
   invalid-message handling, and cleanup.
3. An integration or smoke test shall use a real HTTP request and a real WebSocket
   connection to verify the initial message and at least one subsequent update.
4. The observed interval between consecutive WebSocket messages shall be within
   `750` to `1,500` milliseconds under local test conditions.
5. `run-smoke-tests.sh` shall fail on an invalid payload, missing update, or
   out-of-range interval.
6. The root Maven build and frontend test/build commands shall be runnable in CI.

## Local development

1. `start-dev-local.sh` shall start the backend and frontend and wait for both to
   become ready.
2. `stop-dev-local.sh` shall stop only the processes started by the project.
3. `open-tabs.sh` shall open the application and relevant local developer pages.
4. Scripts shall report actionable errors when required tools or ports are
   unavailable.

## Documentation and CI/CD

1. Module READMEs shall document prerequisites, configuration, commands, and
   endpoints.
2. HTML documentation shall use a linked subpage for the example and a Mermaid
   architecture/message-flow diagram.
3. GitHub Actions shall compile and test the backend and build/test the frontend.
4. Deployment examples shall preserve environment-specific configuration and
   shall not embed secrets.
5. Terraform shall define the Azure resource group, ACR, AKS, monitoring,
   application routing, managed identities, GitHub OIDC federation, and scoped
   deployment role assignments required by the Azure deployment example.
6. Terraform shall expose the non-secret Azure identifiers consumed by GitHub
   Actions and shall not create a client secret.

## Acceptance criteria

- A browser displays a changing `HH:mm:ss` clock obtained through `/ws/clock`.
- The REST endpoint supplies a valid initial clock payload.
- Two consecutive WebSocket messages meet the local cadence tolerance.
- Dropping the backend produces a visible disconnected/error state; restarting it
  allows the frontend to reconnect.
- Unit, build, and smoke commands complete successfully on their stated paths.
- Documentation and tracker evidence identify any verification that requires a
  browser, network access, cloud credentials, or a deployment environment.
- Terraform formatting, provider-schema validation, and mocked plan tests pass;
  Azure plan/apply and hosted rollout evidence remain distinct cloud checks.

## Traceability

- `CONTINUE.md`: tasks 1 through 7
- `requirements/non-functional/REQ-001-no-critical-cves.md`
- `requirements/non-functional/REQ-002-prohibited-licenses.md`
- `requirements/non-functional/REQ-004-api-documentation.md`
- `requirements/non-functional/REQ-007-semantic-versioning.md`
- `requirements/non-functional/REQ-008-openapi-specification.md`
