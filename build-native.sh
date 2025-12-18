#!/bin/bash
set -e

# Ensure Docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker on this Jenkins node."
    exit 1
fi

# Pull the Quarkus native build image
docker pull quay.io/quarkus/ubi-quarkus-native-image:22.3-java17

# Run the native build inside Docker
docker run --rm \
    -v "$PWD":/project \
    -w /project \
    quay.io/quarkus/ubi-quarkus-native-image:22.3-java17 \
    ./mvnw clean package -DskipTests -Pnative -Dquarkus.package.type=uber-jar -X
