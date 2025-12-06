#!/usr/bin/env bash

socat UNIX-LISTEN:/tmp/ssh-agent-dev,fork,user=dev,group=dev,mode=600 \
  UNIX-CONNECT:/ssh-agent &

exec /usr/sbin/sshd -D
