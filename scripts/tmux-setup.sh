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

UBUNTU_VERSION="$(lsb_release -rs)" || exit $?

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit $?
PARENT_DIR="$(dirname "$SCRIPT_DIR")" || exit $?

task-start "Update sources"
apt-yes update || exit $?
task-done "Update sources"

task-start "Setup Wireguard"
$SCRIPT_DIR/wireguard-setup.sh || exit $?
task-done "Setup Wireguard"

task-start "Upgrade system"
apt-yes dist-upgrade || exit $?
task-done "Upgrade system"

# Disable wifi power saving
CONF_ARRAY=(`find /etc/NetworkManager/conf.d/ -maxdepth 1 -name "default-wifi-powersave*.conf"`)
if [ ${#CONF_ARRAY[@]} -gt 0 ]; then
    echo "WiFi power save found, removing"
    for i in "${CONF_ARRAY[@]}"
    do
        rm -rf $i || exit $?
    done
else
    echo "WiFi power save NOT found"
fi

echo '[connection]' > /etc/NetworkManager/conf.d/default-wifi-powersave-off.conf
echo 'wifi.powersave = 2' >> /etc/NetworkManager/conf.d/default-wifi-powersave-off.conf
echo "WiFi power saving disabled"

apt-yes install \
    python-pip \
    python3-pip \
    htop \
    || exit $?

task-start "setup ROS"
$SCRIPT_DIR/ros-setup.sh || exit $?
task-done "setup ROS"

task-start "setup CAN"
$SCRIPT_DIR/can-setup.sh || exit $?
task-done "setup CAN"

task-start "Clean-up packages"
apt --assume-yes autoremove || exit $?
task-done "Clean-up packages"

echo Success! ["$(basename $0)"]
