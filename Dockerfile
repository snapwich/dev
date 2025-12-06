FROM debian:bookworm-slim

# pick unused uid. 65534 is nobody, 65532 is almost nobody.
ARG UID=65532

RUN addgroup --gid ${UID} dev && \
  adduser --disabled-password --gecos '' --uid ${UID} --gid ${UID} dev

# install dependencies
RUN apt-get update && apt-get install -y \
  sudo \
  curl

# github cli repository
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

RUN apt-get update && apt-get install -y \
  build-essential \
  openssh-server \
  socat \
  xdg-utils \
  locales \
  libxkbcommon0 \
  git \
  git-lfs \
  gh \
  lsof \
  rsync \
  zsh \
  jq \
  fzf \
  htop \
  ripgrep \
  fd-find \
  bat \
  tmux \
  stow \
  tree \
  && apt-get clean

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
# n install
RUN curl -L https://bit.ly/n-install | bash -s -- -y

# install gwtmux
RUN --mount=type=ssh,uid=${UID} \
  git clone git@github.com:snapwich/gwtmux.git "$HOME/.local/share/gwtmux"

# install dotfiles (remove files that would conflict before stow)
RUN --mount=type=ssh,uid=${UID} \
  git clone git@github.com:snapwich/dotfiles.git "$HOME/.dotfiles" && \
  rm $HOME/.config/nvim/lua/config/autocmds.lua && \
  rm $HOME/.config/nvim/lua/config/keymaps.lua && \
  rm $HOME/.config/nvim/lua/config/options.lua && \
  stow -t "$HOME" -d "$HOME/.dotfiles" n nvim ssh tmux vim zsh lazygit git

# fix .ssh permissions for SSH StrictModes
RUN chmod 700 $HOME/.ssh

USER root

RUN chsh -s /usr/bin/zsh dev

# sudoers updates
RUN echo "dev ALL=(ALL) NOPASSWD:/usr/bin/lsof" >> /etc/sudoers
RUN mkdir /var/run/sshd
RUN ssh-keygen -A

# update ssh_config to only allow key-based authentication and only our ssh agent
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'UsePAM no' >> /etc/ssh/sshd_config \
  && echo 'PermitRootLogin no' >> /etc/ssh/sshd_config \
  && echo 'AllowUsers dev' >> /etc/ssh/sshd_config \
  && echo 'AllowAgentForwarding no' >> /etc/ssh/sshd_config \
  && echo 'SetEnv SSH_AUTH_SOCK=/tmp/ssh-agent-dev' >> /etc/ssh/sshd_config

# generate locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

# setup our entrypoint with tmp ssh-agent socket accessible by dev user
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22

CMD ["/usr/local/bin/docker-entrypoint.sh"]
