FROM debian@sha256:b7cf494e606bf965e23aa6ee844f0a6b6e78e31bd1099f311e09921e28af3e64

# install ssh server and create runtime directory
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd

# generate ssh host keys
RUN ssh-keygen -A

CMD ["/usr/sbin/sshd", "-D"]