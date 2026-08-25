# Project Memory

## Technology

- Java 21
- Spring Boot 3.x
- Maven
- PostgreSQL
- Flyway
- Testcontainers
- Angular

## Architecture

- REST controllers must not contain business logic.
- Business logic belongs in service classes.
- Database access goes through repository interfaces.
- DTOs must not expose JPA entities.

## Important decisions

- Prefer constructor injection.
- Do not use field injection.
- Do not use Lombok @Data on JPA entities.
- Database migrations must be backwards compatible.

## Known issues

- Integration tests require Docker.
- `legacy-api` module cannot yet be migrated to Java records.

## Useful commands

Build:

    ./mvnw clean verify

Unit tests:

    ./mvnw test

Integration tests:

    ./mvnw verify -Pintegration-tests
