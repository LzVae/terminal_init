#!/bin/bash
# This is a script to init a linux sys's base env
#
# You should put your init script in ./init.d,make sure your script name should be *.sh
# and make them execuable!(chmod u+x ./init.d/yourscript.sh), 
# each init script in init.d is a mode
#
# if you want to init a mode, you should call init.sh with its name(without '.sh') and the username,
# but if you have not specail any mode, this script will use all mode in init.d
# 
# the dir tmp is created for cache tmpfile
# the dir src is created for useful init file like config file(e.g. vimrc)
# 
# this init script init things for a user, so we need a parament to expact username
# if you do this, the INIT_USER=username , INIT_HOME=/home/username
#
# Whenever run this script, it will update pkg manager resource. But it just install base packages
# only once. If you want to reinstall base packages, please remove ./tmp/status.sh.
#
# Usage: 
#      init.sh  username  [mode1, mode2 ...]
#
# Author Mephis Pheies
# Email mephistommm@gmail.com

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
export INIT_USER=$1
[ $INIT_USER == "root" ] && export INIT_HOME=/root || export INIT_HOME=/home/$INIT_USER

#remove the username
shift 

#check user 
if [ $(cut -d ':' -f1 /etc/passwd | grep "$INIT_USER" ) == "" ];then
    echo -e "User $INIT_USER don't exist!"
    exit 1
fi

#get genpath
cd $(dirname $0)
export GENPATH=$(pwd)

#create tmp dir
if [ ! -e $GENPATH/tmp ]; then
    mkdir $GENPATH/tmp
fi

#add package function lib
source $GENPATH/lib/package.sh

update_packages

#if status.sh is not exist, install base packages and create init status file.
#it avoids installing base packages whenever run this script.
#if user want to reinstall them, just remove ./tmp/status.sh.
#
#INIT_STATUS could be used to control the status of init script and other script
#under the ./init.d
if [ ! -e $GENPATH/tmp/status.sh ]; then
    install_packages git wget curl
    export INIT_STATUS=1
    echo "export INIT_STATUS=$INIT_STATUS" > $GENPATH/tmp/status.sh
else
    source $GENPATH/tmp/status.sh
fi

#while parament number(after shifting username) is 0 , init all mode
if [ $# -eq 0 ]; then
    for init_script in $GENPATH/init.d/*.sh; do
        if [ -x $init_script ]; then
            $init_script
        fi
    done
else
    for mode in $@; do
        mode_path=$GENPATH/init.d/$mode.sh
        if [ -e $mode_path -a -x $mode_path ]; then
            $mode_path
        fi
    done
fi

chown -R $INIT_USER:$INIT_USER $INIT_HOME/.local

echo -e "Congratulation!"; exit 0
