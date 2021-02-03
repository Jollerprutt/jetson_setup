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
    echo ">>>> $@"
}

function task-done {
    echo "<<<< [OK] $@"
}

echo Start ["$(basename $0)"]

UBUNTU_VERSION="$(lsb_release -rs)" || exit $?

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit $?
PARENT_DIR="$(dirname "$SCRIPT_DIR")" || exit $?

CONF_ARRAY=(`find $PARENT_DIR/wg_conf/ -maxdepth 1 -name "*.conf"`)
if [ ${#CONF_ARRAY[@]} -gt 0 ]; then
    echo "Wireguard .conf file(s) found"
else
    echo "No Wireguard .conf file(s) found"
    exit $?
fi

task-start "Install Wireguard"
apt-yes update || exit $?
apt-yes install wireguard wireguard-tools || exit $?

task-done "Install Wireguard"

task-start "Secure Wireguard"
chown -R root:root /etc/wireguard/ || exit $?
chmod -R og-rwx /etc/wireguard/* || exit $?

task-done "Secure Wireguard"

task-start "Setup Wireguard"
for i in "${CONF_ARRAY[@]}"
do
    FILE_NAME=$(basename $i .conf)

    mv $i /etc/wireguard/ || exit $?

    systemctl enable wg-quick@$FILE_NAME.service || exit $?
    systemctl start wg-quick@$FILE_NAME.service || exit $?
    # systemctl status wg-quick@$FILE_NAME.service || exit $?
done
task-done "Setup Wireguard"

echo Success! ["$(basename $0)"]
