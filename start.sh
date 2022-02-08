#!/bin/sh

# Allow custom username, default to git
: "${USER:=git}"

if test ! -d "/config/host_keys"; then
  ssh-keygen -A
  mkdir /config/host_keys
  cp -a /etc/ssh/ssh_host_* /config/host_keys
fi

if test ! -f "/config/gitconfig"; then
  cp /default/gitconfig /config
fi

if test ! -f "/config/sshd_config"; then
  cp /default/sshd_config /config
fi

if test ! -d "/jail/home/$USER/git-shell-commands"; then
  cp -r /default/git-shell-commands /jail/home/$USER
fi

if test ! -f "/config/authorized_keys"; then
  touch /config/authorized_keys
fi

# Allow custom sshd_config
rm -f /etc/ssh/sshd_config
cp /config/sshd_config /etc/ssh/sshd_config

# Allow custom host keys
rm -f /etc/ssh/ssh_host_*
cp -a /config/host_keys/* /etc/ssh/


# Create user if it doesn't already exist
if ! id "$USER" &>/dev/null; then
  addgroup $USER
  adduser -D -G $USER -s /usr/bin/git-shell $USER
fi

# Allow custom password
echo git:$PASSWORD | chpasswd

# Copy updated passwd and group files into jail
mkdir -p /jail/etc/
cp /etc/passwd /etc/group /jail/etc

# copy ssh and git user configurations into jail directory
chmod 644 /config/authorized_keys
chown $USER /config/authorized_keys
chmod -R u+x /jail/home/$USER/git-shell-commands
cp /config/gitconfig /jail/etc/gitconfig

chown -R $USER:$USER /jail/home/$USER

/usr/sbin/sshd -D
