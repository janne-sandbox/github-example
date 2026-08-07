Project Task List
Overview
This document tracks the progress of the Hello World real-time clock example project with Java Spring Boot backend and Angular frontend using WebSockets.

# Goals

Your tasks is to follow instructions, and implement, test, and document.
You'll acts as senior developer in project.

# Instructions

Here's project folder structure:
-requirements/functional, is folder where application related requirements go.
Default filepattern is REQ-001-... .md, for example REQ-001-frontend.md
But for applications, e.g. ./kiosk-frontend, you should use pattern
EXAMPLE-REQ-001-... .md
-requirements/non-functional, are more or less non-application specific
requirement. File-patterns there are same, e.g.
REQ-001-... .md
UI-REQ-001-supported-browsers.md

./materials folder is folder where I can supply assistive materials temporary

./documentations folder is where we keep in index.html documentation up-to-date, and ALWAYS add needed subpages, not to create one super-page
Documentation diagrams will be mostly created with Mermaid.

This project will be written with Java (Java Spring Boot), conserning back-ends, and with Angular, conserning front-ends.

Purpose of this project is to create Hello World example with front- and backend.
Backend should update text, e.g. Hello World, clock is <timestamp>
with 1 second interval from backend, and Angular UI should use websocket to receive update.
Main purpose of project is eventually create instructions and examples how github actions can be configured and applied.

Folder ./testing will be intended for integration tests, and unit-tests will be in their own corresponding folders e.g. ./example-backend/...

Task list of progress will be kept in ./CONTINUE.md, and progress is always tracked, meaning that file is updated when single task is finished
When new set of instructions is supplied, you first:
1) Analyze task and Create requirements to ./requirements
2) Update folder README.md e.g. /kiosk-backend/README.md
3) Make implementation
4) (If adviced, create unit- and/or integration tests)
5) Update scripts ./start-dev-local.sh, ./stop-dev-local.sh, ./open-tabs.sh and ./run-smoke-tests.sh -- if needed
6) Test with scripts and verify that everything works
7) Create or update documentation. Remember to create new chapters to index.html, and link those to new subpages when required

Default prod. deployment environment is Azure, but it can be e.g. AWS, GCP, on-premises etc.

# Tasks

1. Requirement Analysis
[ ] Analyze task and create requirements in ./requirements/functional
[ ] Create EXAMPLE-REQ-001-hello-world.md for the real-time clock functionality

2. Backend Implementation (Java Spring Boot)
[ ] Set up Spring Boot project structure
[ ] Implement WebSocket configuration
[ ] Create controller to send time updates every second
[ ] Add REST endpoint for initial page load
[ ] Configure proper dependencies in pom.xml

3. Frontend Implementation (Angular)
[ ] Set up Angular project structure
[ ] Create ClockComponent to display real-time updates
[ ] Implement WebSocket connection to backend
[ ] Add UI elements to show time with HH:MM:SS format
[ ] Implement proper error handling for WebSocket connections

4. Integration and Testing
[ ] Test WebSocket communication between backend and frontend
[ ] Verify real-time updates every second
[ ] Run unit tests for both backend and frontend components
[ ] Execute integration tests using ./run-smoke-tests.sh

5. Documentation
[ ] Update index.html with new documentation chapters
[ ] Create subpages for the new functionality
[ ] Add diagrams in Mermaid format to documentation
[ ] Update README.md files for backend and frontend folders

6. Local Development Scripts
[ ] Update ./start-dev-local.sh to start both backend and frontend
[ ] Update ./stop-dev-local.sh to stop both services
[ ] Update ./open-tabs.sh to open required browser tabs
[ ] Verify all scripts work correctly with the new implementation

7. GitHub Actions Configuration
[ ] Create workflow files for CI/CD
[ ] Configure automated testing
[ ] Set up deployment pipelines
[ ] Document GitHub Actions examples

# Requirements Reference
Each task should reference specific requirement files:

EXAMPLE-REQ-001-hello-world.md - Core real-time clock functionality
