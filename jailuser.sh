#!/bin/bash
#---------------------------------------------------------------------------
# @(#)$Id$
#title       :jailuser.sh
#description :jails existing user with limited commands when they ssh to server.
#author      :Danny W Sheehan
#date        :July 2014
#website     :www.setuptips.com
# ----------------------------------------------------------------------
# jailuser.sh <username> 
#
# This script creates a jailed ssh session for user <username> whenever they
# they login to the server thereafter. The <username> is restricted to
# the list of commands specified in $APPS.

# It should work on most Linux distributions.
# Tested on Ubuntu and Centos.
#
# The users jailed home is under /jail/home/<username>
# A backup is made of <username> old /home directory to /home/<username>.orig
#
# All the libraries needed by the specified $APPS are copied to the chrooted
# environment.
#
# Changes are made to /etc/ssh/sshd_config by the script to set the
# ChrootDirectory.  The ssh server will need to be restarted.
# ----------------------------------------------------------------------
CHROOT_USERNAME=$1

JAILPATH='/jail'
mkdir -p $JAILPATH

#
# Add the apps you want the user to have access to in their jailed 
# environment.
#
APPS="/bin/bash /bin/cat /bin/cp /bin/grep /bin/ls /bin/mkdir /bin/more /bin/mv /bin/pwd /bin/rm /bin/rmdir /usr/bin/du /usr/bin/head /usr/bin/id /usr/bin/less /usr/bin/ssh /usr/bin/scp /usr/bin/tail /usr/bin/rsync"


if ( ! getent group jailed > /dev/null 2>&1 )
then
  echo "creating jailed group"
  groupadd -r jailed
fi 

if ! grep -q "Match group jailed" /etc/ssh/sshd_config
then
  echo "* jailing anyone in jailed group"

  echo "
Match group jailed
  ChrootDirectory $JAILPATH
  AllowTCPForwarding no
  X11Forwarding no
" >> /etc/ssh/sshd_config

  echo
  echo "** please restart ssh daemon, then re-run script again"
  exit 0
fi


if [ -z "$CHROOT_USERNAME" ]
then
  echo "You must specify a username" >&2
  echo "USAGE $0 <username>" >&2
  exit 1
fi

if getent passwd $CHROOT_USERNAME > /dev/null 2>&1
then 
  echo "* User $CHROOT_USERNAME exists. Jailing them"
else
  echo "User $CHROOT_USERNAME does not exist. Add the user first then run this script again" >&2
  exit 3
fi

echo "* adding user to jailed group - so that ssh will jail them automatically when they login"

usermod -a -G jailed ${CHROOT_USERNAME}

group_name=`id -gn ${CHROOT_USERNAME}`

chrooted_home="$JAILPATH/home"
virtual_home="$chrooted_home/$CHROOT_USERNAME"
 

mkdir -p ${chrooted_home}
chown root:root ${chrooted_home}
chmod 755 ${chrooted_home}

echo "* Creating users new jailed home directory" 
mkdir -p ${virtual_home}
chown $CHROOT_USERNAME:$group_name ${virtual_home}
chmod 0700 ${virtual_home}

# If root ever su's to users home this makes sure we go to the correct
# home directory. 

# backup old directory.
if [ -d "/home/${CHROOT_USERNAME}" ]
then
  echo "* Backing up users previous home to /home/${CHROOT_USERNAME}.orig"
  mv /home/${CHROOT_USERNAME} /home/${CHROOT_USERNAME}.orig
fi

if [ ! -e "/home/${CHROOT_USERNAME}" ]
then
  echo "* Creating link from chrooted home to /home"
  ln -s ${virtual_home} /home/${CHROOT_USERNAME}
fi


cd $JAILPATH 
mkdir -p dev
mkdir -p bin
mkdir -p lib64
mkdir -p etc
mkdir -p usr/bin
mkdir -p usr/lib64
 
# First time
if [ ! -f etc/group ] ; then
 echo "* setting up the jail for the first time"
 grep -E "^(nobody|nogroup)" /etc/group > ${JAILPATH}/etc/group
fi

if [ ! -f etc/passwd ] ; then
 grep -E "^(nobody)" /etc/passwd > ${JAILPATH}/etc/passwd
fi

# Append primary group if not already there.
if ( ! grep -q "^${group_name}:" ${JAILPATH}/etc/group )
then 
  grep "^${group_name}:" /etc/group >> ${JAILPATH}/etc/group
fi

# Append this user if not already there.
if ( ! grep -q "^${CHROOT_USERNAME}:" ${JAILPATH}/etc/passwd )
then 
  grep "^${CHROOT_USERNAME}:" /etc/passwd >> ${JAILPATH}/etc/passwd
fi


#
# The libnss_files library is needed so usernames rather than uid's show up
# when users do directory listings.
#
if [ -e "/lib64/libnss_files.so.2" ]
then
 cp -p /lib64/libnss_files.so.2 ${JAILPATH}/lib64/libnss_files.so.2
fi

# Debian/Ubuntu derivatives
if [ -e "/lib/x86_64-linux-gnu/libnss_files.so.2" ]
then
  mkdir -p ${JAILPATH}/lib/x86_64-linux-gnu
  cp -p /lib/x86_64-linux-gnu/libnss_files.so.2 ${JAILPATH}/lib/x86_64-linux-gnu/libnss_files.so.2
fi


# Creating necessary devices
[ -r $JAILPATH/dev/urandom ] || mknod $JAILPATH/dev/urandom c 1 9
[ -r $JAILPATH/dev/null ]    || mknod -m 666 $JAILPATH/dev/null    c 1 3
[ -r $JAILPATH/dev/zero ]    || mknod -m 666 $JAILPATH/dev/zero    c 1 5
[ -r $JAILPATH/dev/tty ]     || mknod -m 666 $JAILPATH/dev/tty     c 5 0

 
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#
# We copy libraries everytime we add a new user to ensure that we
# always have the latest libraries after OS upgrades.
#
for prog in $APPS
do
  cp $prog ${JAILPATH}${prog} > /dev/null 2>&1
  if ( ldd $prog > /dev/null )
  then
    LIBS=`ldd $prog | grep '/lib' | sed 's/\t/ /g' | sed 's/ /\n/g' | grep "/lib"`
    for l in $LIBS
    do
      mkdir -p ./`dirname $l` > /dev/null 2>&1
      cp $l ./$l  > /dev/null 2>&1
    done
  fi
done
 
echo "Chrooted environment created under ${JAILPATH} for ${CHROOT_USERNAME}"
echo
