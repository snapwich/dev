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
