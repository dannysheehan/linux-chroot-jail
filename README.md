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
- The users jailed home is under */jail/home/<username>*
    - A backup is made of <username>'s old /home directory to */home/<username>.orig*
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
