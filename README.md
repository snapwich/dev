for using intellij remote ssh on osx or windows machines inside container (since it only supports linux currently)

with a docker daemon running execute

```bash
./up
```

or to run in background 

```bash
./up -d
```

- host machine's current user keys (and `authorized_keys`) will be mounted to dev container at /home/dev/.ssh
- the dev container will be accessible on port 2222 as "dev" user (e.g. ssh dev@localhost -p 2222 if your user is in `authorized_keys`)
- jetbrains ide config will be mounted to ./home/.config/JetBrains to maintain state between container lifecycles

optionally import your gpg keys to dev container

```bash
./gpg-import
```

you can shell into the dev container as dev with

```bash
./dssh
```

or if you want to install more tools you can either update the Dockerfile and recreate the container or shell into container as root and install them
```bash
./dssh root
```

clone your repo somewhere inside the container and then it will be accessible through JetBrains gateway or intellij remote ssh. the repo files should all be within the container, using a docker volume will not work with intellij (intellij requires file-locking which docker volumes do not support) and using a bind mount to the host machine will be extremely slow when indexing, installing node dependencies, etc.

