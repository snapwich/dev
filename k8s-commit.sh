#!/usr/bin/env sh
set -eu

IMAGE=zot.cluster.snapwich.net/dev:k8s

docker commit k8s "$IMAGE"
docker push "$IMAGE"
