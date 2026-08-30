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
- the container runs as the unprivileged `dev` user (uid 65532). sshd needs root only to setuid into other users, and `AllowUsers dev` means it never does, so it runs as `dev` on port 2222 -- a non-root process cannot bind a port below 1024. use `./dsh root` if you need a root shell.

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

## kubernetes

the Dockerfile has two targets that share the same base: `docker` (default,
socat proxy for the mounted agent socket) and `k8s` (no socket mount, ssh
agent forwarding enabled instead). both run as `dev`, which also makes
`kubectl exec` land as `dev` -- it has no `--user` flag.

build the `k8s` target and push it somewhere your cluster can pull:

```bash
docker build --ssh default --target k8s -t <registry>/dev:latest .
docker push <registry>/dev:latest
```

### ephemeral debug container

attach a throwaway shell to a running pod. the command overrides the default
sshd, so none runs:

```bash
kubectl debug -it <pod> --image=<registry>/dev:latest --target=<container> -- zsh -l
```

use `--profile=sysadmin` if you need ptrace/strace against the target
container.

### full dev environment in a pod

run the image with no command (default is sshd), either as a standalone pod
or as an ephemeral container without `--`:

```bash
kubectl debug <pod> --image=<registry>/dev:latest --target=<container>
```

then port-forward and connect with agent forwarding. `-A` replaces the docker
socket mount, so git/gh auth works the same as locally:

```bash
kubectl port-forward <pod> 2222:2222
ssh -A dev@localhost -p 2222
```

if the pod sets `fsGroup`, kubernetes adds it as a supplementary group at
container start. a non-root sshd cannot call `initgroups()`, so ssh sessions
keep that group -- shared volumes stay writable with no extra setup.

note: with agent forwarding each ssh session gets a new SSH_AUTH_SOCK path.
if you keep long-lived tmux sessions, symlink it to a stable path on login,
e.g. in zshrc:

```bash
[ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ] \
  && ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
```
