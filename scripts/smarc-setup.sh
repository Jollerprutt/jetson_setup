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

export ROS_DISTRO=melodic

# Create known hosts file if missing
runuser -l $(logname) -c 'cd .ssh/ && touch known_hosts' || exit $?

echo "Adding host keys"
runuser -l $(logname) -c 'ssh-keyscan github.com >> ~/.ssh/known_hosts' || exit $?
runuser -l $(logname) -c 'ssh-keyscan gitr.sys.kth.se >> ~/.ssh/known_hosts' || exit $?
runuser -l $(logname) -c 'ssh-keyscan gits-15.sys.kth.se >> ~/.ssh/known_hosts' || exit $?

ARCH=$(dpkg --print-architecture)
if [ "$ARCH" == "arm64" ];
then
    echo "Jetson?"
    task-start "Install Jetson-stats"
    sudo -H pip install -U jetson-stats || exit $?
    task-done "Install Jetson-stats"
fi

task-start "Install sam_robot packages"
$SCRIPT_DIR/rosinstall.sh https://raw.githubusercontent.com/smarc-project/rosinstall/master/sam_robot.rosinstall || exit $?
task-done "Install sam_robot packages"

task-start "Configure uavcan_ros_bridge"
runuser -l $(logname) -c 'cd ~/catkin_ws/src/uavcan_ros_bridge/ && git submodule update --init --recursive' || exit $?
cd /home/$(logname)/catkin_ws/src/uavcan_ros_bridge/libuavcan/libuavcan/dsdl_compiler/pyuavcan && python setup.py install || exit $?
task-done "Configure uavcan_ros_bridge"

echo Success! ["$(basename $0)"]
