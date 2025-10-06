FROM debian:bookworm-slim

# this container is meant to be run using --user as the DEV_UID and DEV_GID which is the same as the host user
ARG UID
ARG GID

RUN if ! getent group $GID >/dev/null; then addgroup --gid $GID dev; fi && \
  adduser --disabled-password --gecos '' --uid $UID --gid $GID dev

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
  libnss3-tools \
  openssh-server \
  xdg-utils \
  default-jre \
  default-jdk \
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
  procps \
  file \
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
RUN ARCH=$(uname -m | sed 's/aarch64/arm64/')&& LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') && \
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" && \
  tar xf /tmp/lazygit.tar.gz lazygit && \
  install lazygit -D -t /usr/local/bin/ && \
  rm -rf /tmp/lazygit*

# install git-delta
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') && curl -Lo /tmp/git-delta.deb https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb && \
  dpkg -i /tmp/git-delta.deb && \
  rm /tmp/git-delta.deb

USER $UID

# install LazyVim for neovim
RUN git clone https://github.com/LazyVim/starter /home/dev/.config/nvim && \
  rm -rf /home/dev/.config/nvim/.git

# oh my zsh installation
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# n install
RUN curl -L https://bit.ly/n-install | bash -s -- -y

# install dotfiles
RUN mkdir -p "$HOME/.dotfiles" && \
  curl -fsSL https://github.com/snapwich/dotfiles/archive/refs/heads/master.tar.gz -o /tmp/dotfiles.tgz && \
  tar -xzf /tmp/dotfiles.tgz --strip-components=1 -C "$HOME/.dotfiles" && \
  stow -t "$HOME" -d "$HOME/.dotfiles" --adopt n nvim ssh tmux vim zsh lazygit git && \
  tar -xzf /tmp/dotfiles.tgz --strip-components=1 -C "$HOME/.dotfiles" && \
  rm -f /tmp/dotfiles.tgz

USER root

RUN username=$(getent passwd $UID | cut -d: -f1) && \
  chsh -s /usr/bin/zsh $username

# sudoers updates
RUN username=$(getent passwd $UID | cut -d: -f1) && \
  echo "$username ALL=(ALL) NOPASSWD:/usr/sbin/sshd, /usr/bin/lsof" >> /etc/sudoers
RUN mkdir /var/run/sshd
RUN ssh-keygen -A

# update ssh_config to only allow key-based authentication
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config \
  && echo 'UsePAM no' >> /etc/ssh/sshd_config

# generate locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

EXPOSE 22

CMD ["sudo", "/usr/sbin/sshd", "-D"]
