#!/usr/bin/env bash

# remove any stale sockets from a previous run
rm -f /tmp/ssh-agent-dev

socat UNIX-LISTEN:/tmp/ssh-agent-dev,fork,user=dev,group=dev,mode=600 \
  UNIX-CONNECT:/ssh-agent &

exec /usr/sbin/sshd -D
