FROM alpine:latest

RUN apk add --no-cache openssh; \
    apk add --no-cache git

VOLUME ["/config", "/jail/home/git"]
COPY git-shell-commands /default/git-shell-commands
COPY sshd_config /default/sshd_config
COPY gitconfig /default/gitconfig
COPY start.sh /start.sh

EXPOSE 22

RUN mkdir -p /jail/dev/		

WORKDIR /jail/dev/
RUN mknod -m 666 null c 1 3; \
    mknod -m 666 tty c 5 0; \
    mknod -m 666 zero c 1 5; \
    mknod -m 666 random c 1 8;

# add base binaries to chroot jail
RUN cp --parents -a /bin/sh \
      /usr/bin/git \
      /usr/bin/git-shell \
      /bin/ls \
      /bin/mkdir \
      /bin/cp \
      /bin/rm \
      /bin/busybox \
      /lib \
      /usr/lib \
      /usr/libexec \
      /usr/share/git-core \
      /jail;

CMD ["/bin/sh", "/start.sh"]
