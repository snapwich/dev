FROM debian:bookworm-slim

# this container is meant to be run using --user as the DEV_UID and DEV_GID which is the same as the host user
ARG UID
ARG GID

RUN addgroup --gid $GID dev && \
    adduser --disabled-password --gecos '' --uid $UID --gid $GID dev

RUN apt-get update && apt-get install -y \
    build-essential \
    openssh-server \
    default-jre \
    default-jdk \
    sudo \
    git \
    curl \
    zsh \
    vim \
    && apt-get clean

# setup home config
COPY --chown=dev:dev ./home /home/dev/

USER dev
# oh my zsh installation
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# n install
RUN curl -L https://bit.ly/n-install | bash -s -- -y
USER root

RUN chsh -s /usr/bin/zsh dev

# sshd dependencies
RUN echo 'dev ALL=(ALL) NOPASSWD:/usr/sbin/sshd' >> /etc/sudoers
RUN mkdir /var/run/sshd
RUN ssh-keygen -A

# update sshd_config to listen on port 2222 and only allow key-based authentication
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
    && echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config \
    && echo 'UsePAM no' >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["sudo", "/usr/sbin/sshd", "-D"]
