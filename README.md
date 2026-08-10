# github-example

Requirements-driven Hello World clock example using Spring Boot, Angular, REST,
and WebSockets. See `CONTINUE.md` for current implementation and verification
status.

## Local scripts

- `./start-dev-local.sh` builds and starts both applications, checks ports, and
  waits for readiness.
- `./run-smoke-tests.sh` checks backend health, REST JSON, frontend HTML, and two
  real WebSocket messages.
- `OPEN_BROWSER=false ./open-tabs.sh` prints the local URLs without opening a
  browser.
- `./stop-dev-local.sh` stops only processes recorded in the project's `.run/`
  directory.

## Quick start

Prerequisites are Java 21 or newer, Maven 3.9 or newer, Node.js 26, npm 11, and
`curl`.

```bash
cd example-frontend
npm ci
cd ..
./start-dev-local.sh
./run-smoke-tests.sh
./stop-dev-local.sh
```

The application is available at `http://localhost:4200`. The backend REST and
WebSocket endpoints default to ports `8080` and are configurable as documented in
the module READMEs.

## Azure infrastructure

The `terraform/` root module provisions the resource group, ACR, AKS, monitoring,
managed application routing, explicit AKS identities, and the environment-scoped
GitHub OIDC deployment identity. See `terraform/README.md` for cost warnings,
state configuration, validation, apply, GitHub variable, and post-deployment
verification instructions.
