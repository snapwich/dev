FROM debian:trixie-slim AS base

# pick unused uid. 65534 is nobody, 65532 is almost nobody.
ARG UID=65532

RUN groupadd --gid ${UID} dev && \
  useradd --uid ${UID} --gid ${UID} -m -s /bin/sh dev

# install dependencies necessary for managing keyrings
RUN apt-get update && apt-get install -y \
  sudo \
  curl \
  gnupg \
  lsb-release \
  && rm -rf /var/lib/apt/lists/*

# github cli repository
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# hashicorp (vault) repository
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg \
  && chmod go+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# SKIP_SETCAP=yes to prevent mlock in vault
RUN apt-get update && SKIP_SETCAP=yes apt-get install -y \
  build-essential \
  openssh-server \
  libnss3-tools \
  socat \
  xdg-utils \
  locales \
  libxkbcommon0 \
  libicu76 \
  libcap2-bin \
  git \
  git-lfs \
  gh \
  python3-venv \
  lsof \
  rsync \
  zsh \
  jq \
  fzf \
  htop \
  ripgrep \
  fd-find \
  bat \
  du-dust \
  tmux \
  stow \
  just \
  tree \
  vault \
  unzip \
  uuid-runtime \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# link fd-find to fd
RUN ln -s "$(which fdfind)" /usr/local/bin/fd

# link batcat to bat
RUN ln -s "$(which batcat)" /usr/local/bin/bat

# install latest neovim stable from github releases
RUN ARCH=$(uname -m | sed 's/aarch64/arm64/') && \
  curl -LO "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${ARCH}.tar.gz" && \
  tar -xzf "nvim-linux-${ARCH}.tar.gz" && \
  cp -r "nvim-linux-${ARCH}"/* /usr/local/ && \
  rm -rf "nvim-linux-${ARCH}" "nvim-linux-${ARCH}.tar.gz"

# install LazyGit
RUN ARCH=$(uname -m | sed 's/aarch64/arm64/') && LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') && \
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" && \
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && \
  install /tmp/lazygit -D -t /usr/local/bin/ && \
  rm -rf /tmp/lazygit*

# install git-delta
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') && curl -Lo /tmp/git-delta.deb https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb && \
  dpkg -i /tmp/git-delta.deb && \
  rm /tmp/git-delta.deb

USER dev

# make an empty .ssh folder so stow doesn't symlink the whole .ssh folder
RUN mkdir -p $HOME/.ssh && ssh-keyscan github.com >> $HOME/.ssh/known_hosts

# install LazyVim for neovim
RUN --mount=type=ssh,uid=${UID} \
  git clone git@github.com:LazyVim/starter.git $HOME/.config/nvim && \
  rm -rf $HOME/.config/nvim/.git

# oh my zsh installation
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# n install. drop n's download cache, it is a second copy of the installed
# node. `n <version>` downloads it again when needed.
RUN curl -L https://bit.ly/n-install | bash -s -- -y \
  && rm -rf $HOME/n/n/versions

# n puts node in $HOME/n/bin, but only .zprofile adds it to PATH and that is a
# login shell file. bake it into the image config so non-login shells,
# `docker exec` and `kubectl exec` find node too.
ENV N_PREFIX="/home/dev/n"
ENV PATH="/home/dev/n/bin:${PATH}"

# install gwtmux
RUN --mount=type=ssh,uid=${UID} \
  git clone git@github.com:snapwich/gwtmux.git "$HOME/.local/share/gwtmux"

# install dotfiles (remove files that would conflict before stow)
RUN --mount=type=ssh,uid=${UID} \
  git clone git@github.com:snapwich/dotfiles.git "$HOME/.dotfiles" && \
  rm $HOME/.config/nvim/lua/config/autocmds.lua && \
  rm $HOME/.config/nvim/lua/config/keymaps.lua && \
  rm $HOME/.config/nvim/lua/config/options.lua && \
  stow -t "$HOME" -d "$HOME/.dotfiles" claude n nvim ssh tmux vim zsh lazygit git

# fix .ssh permissions for SSH StrictModes
RUN chmod 700 $HOME/.ssh

USER root

RUN chsh -s /usr/bin/zsh dev

# k9s/kubectl exec start bash explicitly (no login, so chsh doesn't apply);
# hand interactive bash over to zsh.
RUN printf '%s\n' 'case $- in *i*) [ -z "${ZSH_VERSION-}" ] && [ -t 1 ] && command -v zsh >/dev/null && exec zsh;; esac' >> /etc/bash.bashrc

# sudoers updates
RUN echo "dev ALL=(ALL) NOPASSWD:/usr/bin/lsof" >> /etc/sudoers
RUN mkdir -p /var/run/sshd
RUN ssh-keygen -A

# update ssh_config to only allow key-based authentication.
# port 2222: a non-root sshd cannot bind a port below 1024.
# PidFile none: a non-root sshd cannot write /run/sshd.pid.
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'KbdInteractiveAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'UsePAM no' >> /etc/ssh/sshd_config \
  && echo 'PermitRootLogin no' >> /etc/ssh/sshd_config \
  && echo 'AllowUsers dev' >> /etc/ssh/sshd_config \
  && echo 'Port 2222' >> /etc/ssh/sshd_config \
  && echo 'PidFile none' >> /etc/ssh/sshd_config

# sshd requires host keys owned by the user it runs as
RUN chown dev:dev /etc/ssh/ssh_host_*_key*

# generate locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

EXPOSE 2222

# kubernetes target: no mounted agent socket, use ssh agent forwarding instead
# build with: docker build --ssh default --target k8s -t <registry>/dev .
FROM base AS k8s

RUN echo 'AllowAgentForwarding yes' >> /etc/ssh/sshd_config

# in a j2 Sandbox the worktrees (/work) and their read-only clone source
# (/repos) are created by the harness container's uid, so git's dubious
# ownership guard fires for dev. system config because $HOME/.gitconfig is
# stowed; trailing /* needs git >= 2.46 (trixie ships 2.47).
RUN git config --system --add safe.directory '/work/*' \
  && git config --system --add safe.directory '/repos/*'

# run as dev so `kubectl exec` lands as dev (it has no --user flag).
# sshd needs root only to setuid into other users; `AllowUsers dev` means
# it never does.
USER dev

CMD ["/usr/sbin/sshd", "-D", "-e"]

# docker target (default): host agent socket mounted at /ssh-agent, proxied
# by socat to a dev-owned socket. agent forwarding not needed.
FROM base AS docker

RUN echo 'AllowAgentForwarding no' >> /etc/ssh/sshd_config \
  && echo 'SetEnv SSH_AUTH_SOCK=/tmp/ssh-agent-dev' >> /etc/ssh/sshd_config

# the mounted /ssh-agent socket is owned by the host user and mode 600, so
# only root can connect to it. ssh-agent-proxy is a root-owned wrapper with
# the socat command hardcoded; the `""` in sudoers permits it with no
# arguments only, so this grants one fixed action, not a root shell.
COPY ssh-agent-proxy.sh /usr/local/bin/ssh-agent-proxy
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/ssh-agent-proxy /usr/local/bin/docker-entrypoint.sh \
  && echo 'dev ALL=(ALL) NOPASSWD: /usr/local/bin/ssh-agent-proxy ""' > /etc/sudoers.d/ssh-agent-proxy \
  && chmod 440 /etc/sudoers.d/ssh-agent-proxy \
  && visudo -c

USER dev

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
