# Build from the project root with:
# docker build -f investment_ontology_serverpod_server/Dockerfile .

# Build stage
FROM dart:3.13.4 AS build

# Create a minimal workspace that preserves locked server dependency versions.
WORKDIR /app
COPY pubspec.lock .
COPY investment_ontology_serverpod_server investment_ontology_serverpod_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.13.4' \
  'workspace:' \
  '  - investment_ontology_serverpod_server' \
  > pubspec.yaml
RUN dart pub get

# Compile the server executable.
WORKDIR /app/investment_ontology_serverpod_server
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server

# Add a fallback for the copy of possibly missing directories.
RUN mkdir -p config web migrations assets

# Final stage
FROM alpine:latest
WORKDIR /app

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Run as an unprivileged user. The server only reads its compiled binary,
# static assets and config at startup (session logs and future-call state go
# to the database, not local disk), so nothing here needs to be writable.
RUN addgroup -S serverpod && adduser -S -G serverpod -h /app serverpod

# Copy compiled server executable and native libraries
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/build/bundle/ ./

# Copy configuration files and resources
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/config/ config/
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/web/ web/
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/migrations/ migrations/
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/assets/ assets/

# This file is required to enable the endpoint log filter in Insights.
COPY --from=build --chown=serverpod:serverpod /app/investment_ontology_serverpod_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

USER serverpod

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Define the entrypoint command
ENTRYPOINT ./bin/server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role
