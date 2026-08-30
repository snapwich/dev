#!/usr/bin/env sh
set -eu

IMAGE=zot.cluster.snapwich.net/dev:k8s

docker build --ssh default --target k8s -t "$IMAGE" .

docker rm -f k8s >/dev/null 2>&1 || true
docker run -d --name k8s "$IMAGE"
