FROM debian:bookworm-slim

# this container is meant to be run using --user as the DEV_UID and DEV_GID which is the same as the host user
ARG UID
ARG GID

RUN if ! getent group $GID >/dev/null; then addgroup --gid $GID dev; fi && \
    adduser --disabled-password --gecos '' --uid $UID --gid $GID dev

RUN apt-get update && apt-get install -y \
    build-essential \
    openssh-server \
    xdg-utils \
		default-jre \
    default-jdk \
    sudo \
    git \
    curl \
    zsh \
    vim \
		fzf \
    && apt-get clean

# setup home config
COPY --chown=$UID:$GID ./home /home/dev/

USER $UID
# oh my zsh installation
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# n install
RUN curl -L https://bit.ly/n-install | bash -s -- -y
USER root

RUN username=$(getent passwd 504 | cut -d: -f1) && \
		chsh -s /usr/bin/zsh $username

# sshd dependencies
RUN username=$(getent passwd 504 | cut -d: -f1) && \
		echo "$username ALL=(ALL) NOPASSWD:/usr/sbin/sshd" >> /etc/sudoers
RUN mkdir /var/run/sshd
RUN ssh-keygen -A

# update sshd_config to listen on port 2222 and only allow key-based authentication
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
    && echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config \
    && echo 'UsePAM no' >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["sudo", "/usr/sbin/sshd", "-D"]
