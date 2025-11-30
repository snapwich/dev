# Container Dev

for quickly setting up a dev container accessible through ssh

```bash
./up --build
```

or to run in background

```bash
./up --build -d
```

- `authorized_keys` comes from [my dotfiles repository](https://github.com/snapwich/dotfiles/blob/master/ssh/.ssh/authorized_keys)
- if no $SSH_SOCK_AUTH is set, will default to Docker Desktop/Colima (`colima start --ssh-agent`) default of /run/host-services/ssh-auth.sock
- the dev container will be accessible on port 2222 as "dev" user (e.g. ssh dev@localhost -p 2222 if your user is in `authorized_keys`)

optionally import your gpg keys to dev container

```bash
./gpg-import
```

you can shell into the dev container as dev with

```bash
./dsh
```

or if you want to install more tools you can either update the Dockerfile and recreate the container or shell into container as root and install them

```bash
./dsh root
```

clone your project repo somewhere inside the container and then it will be accessible through remote ssh. your project files should all remain in the container. using a docker volume with a bind mount to the host machine would be extremely slow if indexing, installing node dependencies, etc.
