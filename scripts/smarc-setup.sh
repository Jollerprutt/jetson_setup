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

task-start "SMaRC packages"
export ROS_DISTRO=melodic

PACKAGE_NAME=sam_robot.rosinstall
PACKAGE_PATH=/home/$(logname)/catkin_ws/src/${PACKAGE_NAME}

if [ -f "$PACKAGE_PATH" ]; then
    echo "${PACKAGE_NAME} already exists, replacing"
    rm -rf $PACKAGE_PATH
fi

cmd=$( printf 'cd ~/catkin_ws/src/ && wget https://raw.githubusercontent.com/smarc-project/rosinstall/master/%q' "${PACKAGE_NAME}" ) || exit $?
runuser -l $(logname) -c "$cmd" || exit $?

echo "Converting to SSH access"
sed -i 's/https:\/\//git@/g' ${PACKAGE_PATH}
sed -i 's/\.com\//\.com:/g' ${PACKAGE_PATH}
sed -i 's/\.se\//\.se:/g' ${PACKAGE_PATH}

echo "Installing packages"
cmd=$( printf 'cd ~/catkin_ws/src/ && vcs import --recursive --w 1 < %q' "${PACKAGE_NAME}" ) || exit $?
runuser -l $(logname) -c "$cmd" || exit $?

# TODO add Jetson stats and ros package

task-done "SMaRC packages"

echo Success! ["$(basename $0)"]
