FROM debian:bookworm-slim

# this container is meant to be run using --user as the DEV_UID and DEV_GID which is the same as the host user
ARG UID
ARG GID

RUN if ! getent group $GID >/dev/null; then addgroup --gid $GID dev; fi && \
    adduser --disabled-password --gecos '' --uid $UID --gid $GID dev

RUN apt-get update && apt-get install -y sudo

# github cli repository
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
		&& sudo mkdir -p -m 755 /etc/apt/keyrings \
		&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
		&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
		&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

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
		curl \
		lsof \
		rsync \
		zsh \
		jq \
		fzf \
		htop \
  	ripgrep \
		tmux \
		procps \
		file \
		&& apt-get clean

# setup home config
COPY --chown=$UID:$GID ./home /home/dev/

# install latest neovim stable from github releases
RUN NVIM_ARCH=$(uname -m | sed 's/aarch64/arm64/') && \
    curl -LO "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${NVIM_ARCH}.tar.gz" && \
    tar -xzf "nvim-linux-${NVIM_ARCH}.tar.gz" && \
    cp -r "nvim-linux-${NVIM_ARCH}"/* /usr/local/ && \
    rm -rf "nvim-linux-${NVIM_ARCH}" "nvim-linux-${NVIM_ARCH}.tar.gz"

USER $UID

# install LazyVim for neovim
RUN git clone https://github.com/LazyVim/starter /home/dev/.config/nvim && \
    rm -rf /home/dev/.config/nvim/.git

# oh my zsh installation
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# n install
RUN curl -L https://bit.ly/n-install | bash -s -- -y
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
