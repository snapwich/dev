# Container Dev

for quickly setting up a dev container accessible through ssh

```bash
./up --build
```

or to run in background

```bash
./up --build -d
```

- `authorized_keys` comes from [my dotfiles repository](https://github.com/snapwich/dotfiles/blob/master/ssh/.ssh/authorized_keys). if you would like to use this container for yourself fork and/or create your own dotfiles repo with your own configuration (or at least your own keys) and update the `Dockerfile` to reflect the new dotfiles repo location.
- if no $SSH_SOCK_AUTH is set, will default to Docker Desktop/Colima (`colima start --ssh-agent`) default of /run/host-services/ssh-auth.sock, this allows agent forwarding from host -> vm -> container
  - if you see `failed to convert agent config` error when running `./up` then $SSH_SOCK_AUTH is probably not set when it should be. no local ssh-agent and/or no ssh-auth.sock from vm provider.
- the dev container will be accessible on port 2222 as "dev" user (e.g. ssh dev@localhost -p 2222 if your user is in `authorized_keys`)

optionally configure your container for commit signing. ssh key signing is preferable to gpg signing
since you can re-use the existing ssh-agent socket for signing commits.

```bash
git config --global gpg.format ssh # (if not already set from dotfiles)
# publickey is coming from dotfiles, otherwise you need to copy to container
git config --global user.signingkey ~/.ssh/<keyfile>.pub
# gpgsign is used for ssh signing as well
git config --global commit.gpgsign  true
```

all of these commands can either be in the global config or local repo config if some repos require
signing and others don't. if you're stowing `~/.gitconfig` from your dotfiles repo it might be preferable
to configure these things in `~/.gitconfig.local` and include that from your `~/.gitconfig`.

you can shell into the dev container as dev with

```bash
./dsh
```

or if you want to install more tools you can either update the Dockerfile and recreate the container or shell into container as root and install them

```bash
./dsh root
```

clone your project repo somewhere inside the container and then it will be accessible through remote ssh. your project files should all remain in the container. using a docker volume with a bind mount to the host machine would be extremely slow if indexing, installing node dependencies, etc.
