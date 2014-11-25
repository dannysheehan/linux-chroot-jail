# jailuser.sh

~~~
jailuser.sh <username> 
~~~

This script creates a jailed ssh session for user <username> whenever they
they login to the server thereafter. The <username> is restricted to
the list of commands specified in **$APPS**.

It should work on most Linux distributions.
Tested on Ubuntu and Centos.

The users jailed home is under */jail/home/<username>*
A backup is made of <username>'s old /home directory to */home/<username>.orig*

All the libraries needed by the specified $APPS are copied to the chrooted
environment automatically.

## NOTE
- Changes are made to */etc/ssh/sshd_config* by the script to set the
ChrootDirectory.  The ssh server will need to be restarted manually for
the change to take effect.
- Here are the changes made
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
