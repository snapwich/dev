# Container Dev

for quickly setting up a dev container accessible through ssh

```bash
./up --build
```

or to run in background

```bash
./up --build -d
```

- host machine's `authorized_keys` will be mounted to dev container at /home/dev/.ssh/authorized_keys
- an ssh-agent will be started to forward default keys to the container (start an agent before calling `./up` if you want specific keys)
- the dev container will be accessible on port 2222 as "dev" user (e.g. ssh dev@localhost -p 2222 if your user is in `authorized_keys`)

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

clone your project repo somewhere inside the container and then it will be accessible through remote ssh. your project files should all remain in the container. using a docker volume with a bind mount to the host machine would be extremely slow if indexing, installing node dependencies, etc.
