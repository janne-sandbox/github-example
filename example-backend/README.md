# Example backend

Spring Boot backend for `EXAMPLE-REQ-001`. It provides the initial clock value
over HTTP and broadcasts live values over WebSocket.

## Local endpoints

- `GET http://localhost:8080/api/v1/clock`
- `ws://localhost:8080/ws/clock`
- `GET http://localhost:8080/actuator/health`

## Prerequisites

- Java 21
- Maven 3.9 or newer, or the project Maven wrapper when available

## Commands

```bash
mvn -pl example-backend spring-boot:run
mvn -pl example-backend test
```

## Configuration

| Setting | Default | Purpose |
|---|---|---|
| `server.port` | `8080` | HTTP and WebSocket listener |
| `FRONTEND_ORIGIN` | `http://localhost:4200` | Allowed REST/WebSocket browser origin |
| `example.clock.broadcast-interval` | `1s` | Scheduled broadcast cadence |

`GET /api/v1/clock` and `/ws/clock` both return JSON shaped as:

```json
{
  "text": "Hello World, clock is 2026-08-10T12:34:56Z",
  "timestamp": "2026-08-10T12:34:56Z"
}
```

The WebSocket sends one immediate value and then values approximately once per
second. Failed sessions are isolated from other clients. Current verification
evidence is tracked in `../CONTINUE.md`.
