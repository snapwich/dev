#!/usr/bin/env sh
# build the k8s image and start a container to customize by hand. edit it with
#   docker exec -it k8s zsh -l
# then run ./k8s-commit.sh to save the result back to the image and push it.
#
# the image is built for the architecture of the docker host and tagged with it,
# so the same tag can be built on an amd64 and an arm64 machine without one
# replacing the other. log in first with `docker login zot.cluster.snapwich.net`.
set -eu

REPO=zot.cluster.snapwich.net/dev
ARCH=$(docker version --format '{{.Server.Arch}}')

docker build --ssh default --target k8s -t "$REPO:k8s-$ARCH" .

docker rm -f k8s >/dev/null 2>&1 || true
docker run -d --name k8s "$REPO:k8s-$ARCH"
