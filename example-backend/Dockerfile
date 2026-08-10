# syntax=docker/dockerfile:1.7
ARG BUILDPLATFORM=linux/amd64
ARG TARGETPLATFORM

FROM --platform=${BUILDPLATFORM} maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml ./pom.xml
COPY example-backend/pom.xml ./example-backend/pom.xml
COPY example-backend/src ./example-backend/src
RUN mvn --batch-mode --no-transfer-progress -pl example-backend package -DskipTests

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S example && adduser -S -G example -u 10001 example
WORKDIR /app
COPY --from=build /workspace/example-backend/target/example-backend-1.0.0-SNAPSHOT.jar ./application.jar
USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/application.jar"]
