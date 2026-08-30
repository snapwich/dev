#!/usr/bin/env sh
set -eu

IMAGE=zot.cluster.snapwich.net/dev:k8s

docker build --ssh default --target k8s -t "$IMAGE" .
docker push "$IMAGE"
