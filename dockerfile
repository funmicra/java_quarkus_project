
FROM ubuntu:22.04

  

WORKDIR /app

COPY target/java-quarkus-1.0.0-runner /app/java-quarkus-runner

RUN chmod +x /app/java-quarkus-runner

  

EXPOSE 8080

ENV QUARKUS_HTTP_HOST=0.0.0.0

ENV QUARKUS_HTTP_PORT=8080

  

ENTRYPOINT ["/app/java-quarkus-runner"]