#!/usr/bin/env bash
set -eu

sudo /usr/local/bin/ssh-agent-proxy &

exec /usr/sbin/sshd -D -e
