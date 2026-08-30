#!/usr/bin/env bash
# Runs as root through sudo. Bridges the host ssh-agent socket mounted at
# /ssh-agent (owned by the host user, mode 600) to a socket the dev user can
# open. Takes no arguments on purpose: the sudoers rule allows this script
# only with an empty argument list, so nothing here is caller-controlled.
set -eu

SOCKET=/tmp/ssh-agent-dev

# remove any stale socket from a previous run
rm -f "$SOCKET"

exec socat "UNIX-LISTEN:${SOCKET},fork,user=dev,group=dev,mode=600" \
  UNIX-CONNECT:/ssh-agent
