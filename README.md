> **Archived.** This script is from 2014. It copies a small userspace into `/jail` and points OpenSSH `ChrootDirectory` at it, which was useful when that was tedious to do by hand.
>
> It is not a good 2026 setup:
> - For SFTP-only users, use OpenSSH `ForceCommand internal-sftp` and `ChrootDirectory`. No copied binaries needed.
> - vsftpd is mentioned below but this script does not configure it. vsftpd has `chroot_local_user`.
> - For an interactive restricted shell, use [jailkit](https://olivierbert.github.io/jailkit/) or similar. chroot is a weak boundary once the user has `bash`, and this jail also copies in `ssh`, `scp`, and `rsync`.
>
> Left here as a historical example of the `ldd`-copy approach.

linux-chroot-jail
=================

Scripts to jail Linux users for ssh, sftp and vsftp

## jailuser.sh

~~~
jailuser.sh <user> 
~~~

This script enforces jailed ssh sessions for the specified  *user* whenever 
they they login to the server thereafter. The *user* is restricted to
the list of commands specified in **$APPS**.

- It should work on most Linux distributions.
    - So far tested on Ubuntu and Centos.
- The users jailed home is under */jail/home/user*
    - A backup is made of *user*'s old /home directory to */home/user.orig*
- All the libraries needed by the specified $APPS are copied to the chrooted
environment automatically.

### NOTE
- Changes are made to */etc/ssh/sshd_config* by the script to set 
*ChrootDirectory*.  The ssh server will need to be restarted manually for
the change to take effect.
- Here are the changes that are made to *sshd_config*
```
Match group jailed
  ChrootDirectory /fhome/jail
  AllowTCPForwarding no
  X11Forwarding no
```
- additional recommended change
```
PermitRootLogin no
AllowGroups wheel jailed
```
