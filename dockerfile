FROM ubuntu:22.04 AS base


RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app


COPY target/demo-quarkus-1.0.0-runner /app/demo-quarkus-runner
RUN chmod +x /app/demo-quarkus-runner



FROM gcr.io/distroless/base-debian12 AS runtime

WORKDIR /app


COPY --from=base /app/demo-quarkus-runner /app/demo-quarkus-runner

ENV QUARKUS_HTTP_HOST=0.0.0.0
ENV QUARKUS_HTTP_PORT=8080

EXPOSE 8080

ENTRYPOINT ["/app/demo-quarkus-runner"]
