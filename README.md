# Git SSH Server Docker
A Docker image for easily setting up an ssh based git server.

### Note: this image is in the beta development stage.
* Some breaking changes may occur between updates, this will be indicated by updating the minor version in the version string (e.g. the Y in vX.Y.Z).
* Currently this image is only suitable for running with a single user. In the future it is planned to be updated to add support for multiple users.
* The current default commands provided for interactive shell access are very limited and are planned to be expanded upon.

## Using this image
### Basic Example
1. Start a container using this image, forwarding port 22, and mounting the `/config` and `/jail/home/git` directories:
```
docker run -d -p 22:22 -v config:/config -v repositories:/jail/home/git ghcr.io/pfeiferj/git-ssh-server-docker:latest
```

2. Add an ssh public key to `config/authorized_keys`.
	* Generate an ssh key: `ssh-keygen`
	* Add the generated ssh key to the authorized_keys file: `cat ~/.ssh/id_rsa.pub >> config/authorized_keys`
3. Login via ssh to the server: `ssh git@127.0.0.1`
4. Create an empty repo using: `create-repo my-example-repo`
5. Disconnect from the server and clone the repo you created: `git clone git@127.0.0.1:my-example-repo`
	* If you forwarded a port other than 22 then you must use an ssh url containing the full path to the repo: `git clone ssh://git@127.0.0.1:2222/home/git/my-example-repo`
6. You can now commit files to the cloned repo and push to the server.

### Persistent Data
There are two directories that should have mounts bound to them:

1. **/config/**: This directory contains important configuration files related to openssh and git. If any of the files do not exist on the filesystem this image will create default files.
	* **authorized_keys**: This file contains public ssh keys used to authenticate clients. Any public keys added to this file will immediately be usable for logging in without restarting the container. The default file is empty.
	* **gitconfig**: This file contains git configuration settings for the user on the server. The default file sets git's default branch to main on repositories created from the server. Check the git man pages (`man git-config`) for more info about this file.
	* **host_keys/**: This directory contains the openssh server public and private keys. By default the image will generate new keys on startup using "ssh-keygen -A" if this folder does not contain any keys.
	* **sshd_config**: This file contains the openssh server configuration. The default configuration file only allows the user "git" to login and places that user in a chroot jail with limited binaries available. The default configuration also disables all forms of ssh forwarding/tunneling. Check the openssh man page (`man sshd_config`) for more info about the settings in this file.

2. **/jail/home/git/**: This directory contains the git repositories as well as the commands available to a user logged in via an ssh client.
	* **git-shell-commands/**: Executable files in this directory can be ran by a user logged in via an ssh client. These are the only commands available to the logged in user. If this folder does not exist the image will create the directory and add some default commands. Check the git man pages for more details about the git-shell (`man git-shell`).
	* Other folders added here should be git repositories. If the repositories were created using the default create-repo command then the folders will be a "bare" git repo which is essentially the .git folder contained inside of the repo once you have cloned it.

### Changing the username
To change the username to something other than the default of "git" you can provide a USER environment variable. If you change the username then you must also update the sshd_config to allow the new username. Changing the username also changes the mount point for the repositories. Instead of mounting your repositories to `/jail/home/git` you must mount them to `/jail/home/$USER` where $USER is the name you provide in the USER environment variable.
### Password based login
To enable password based login you must provide a PASSWORD environment variable containing the password you wish to login with. Note that this is less secure than using public key based authentication. Enabling password based login does not disable public key based authentication by default.

### Further hardening of security
#### Disabling password based login
By default the user created will not have a password and the default ssh configuration does not allow empty password logins. This means by default the only way to login to the user is with public key authentication. However, you can further harden this by explicitly disabling password based authentication in the sshd_config file. This can be done by adding `PasswordAuthentication no` to the sshd_config file.

#### Removing shell access
By default this image creates a chroot jail with limited binaries available and sets the user shell to the git-shell. The git-shell only allows commands related to the git push/pull process and commands/executables that are placed in the `git-shell-commands` to be ran. To disable interactive access and only allow the commands necessary to operate the git server you can remove all of the files from the `git-shell-commands` folder and then add a `no-interactive-login` executable script to it. If a script by the name of `no-interactive-login` exists then the git-shell will run the script and then immediately exit the shell. Check the git man pages to get more information about the git-shell (`man git-shell`).

#### Custom host ssh keys
By default this image will create host ssh keys using the `ssh-keygen -A` command provided by openssh. This command creates keys for each supported key type using openssh's default settings for each key. If you would like to customize the types of keys that are available or the settings on those keys you can place keys that you have generated in the host_keys folder. If the host_keys folder exists this image will not create any new keys on startup and will only use keys that already exist in the folder. This can also be used to keep host keys from another ssh server if migrating to this image.

#### Explicit default options in sshd_config
The default configuration for openssh provided by this image relies heavily on openssh's default configuration values to provide a secure environment. This means that if openssh changes any of those defaults in the future it could result in unintentionally opening up the server. While it is unlikely that these defaults will ever change due to many ssh servers relying on them, you can explicitly set any options you see fit in the sshd_config file. Check the openssh man pages for details about the sshd_config file (`man sshd_config`).

