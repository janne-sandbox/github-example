---
name: Clock Update
version: 1.0.0
summary: The backend broadcasts the current clock payload to connected WebSocket clients.
owners:
  - example-backend
---

# Clock Update

This event is derived from the Spring Boot clock service and Angular WebSocket client. The backend sends an initial payload and approximately one update per second over the configured clock WebSocket endpoint.

See [the generated implementation source inventory](../docs/implementation-source.md).
