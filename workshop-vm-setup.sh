#!/bin/bash
if [ `whoami` != 'root' ];
then
    echo "This program must be run with 'sudo'"
    exit
fi

function apt-yes {
    apt --assume-yes "$@"
}

function task-start {
    echo ">> $@"
}

function task-done {
    echo "<< [OK] $@"
}

echo Start ["$(basename $0)"]

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit $?

task-start "Dist upgrade"
apt-yes update || exit $?
apt-yes dist-upgrade || exit $?
task-done "Dist upgrade"

NO_MACHINE_VERSION=nomachine_7.1.3_1_amd64.deb
task-start "Install NoMachine"
wget https://download.nomachine.com/download/7.1/Linux/$NO_MACHINE_VERSION || exit $?
dpkg -i $NO_MACHINE_VERSION || exit $?
task-done "Install NoMachine"

task-start "Change to swedish keyboard layout"
sed -i 's/XKBLAYOUT="us"/XKBLAYOUT="se"/g' /etc/default/keyboard || exit $?
task-done "Change to swedish keyboard layout"

task-start "Set password"
PASSWORD=workshop
echo -e "$PASSWORD\n$PASSWORD" |passwd $1 || exit $?
task-done "Set password"

task-start "Install ROS"
$SCRIPT_DIR/scripts/ros-setup.sh $1 || exit $?
task-done "Install ROS"

echo VM deployed successfully!
