#!/usr/bin/env sh
# save hand-made changes in the `k8s` container back to the image and push it.
# no -c flags: commit already inherits USER dev, CMD sshd, EXPOSE 2222 and PATH
# from the running container.
#
# the commit goes to an arch-specific tag. `:k8s` is then rebuilt as a manifest
# list over every arch tag the registry holds, so pushing from one machine keeps
# the other machine's architecture. that step runs in the registry and moves no
# image data.
set -eu

REPO=zot.cluster.snapwich.net/dev
ARCH=$(docker version --format '{{.Server.Arch}}')

docker commit k8s "$REPO:k8s-$ARCH"
docker push "$REPO:k8s-$ARCH"

SRC=""
for a in amd64 arm64; do
  if docker buildx imagetools inspect "$REPO:k8s-$a" >/dev/null 2>&1; then
    SRC="$SRC $REPO:k8s-$a"
  fi
done

# shellcheck disable=SC2086
docker buildx imagetools create -t "$REPO:k8s" $SRC
