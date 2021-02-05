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
    echo ">>>>>> $@"
}

function task-done {
    echo "<<<<<< [OK] $@"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit $?

PACKAGE_NAME=$(echo $1 | sed 's#.*/##')
PACKAGE_PATH=/home/$(logname)/catkin_ws/src/${PACKAGE_NAME}

if [ -f "$PACKAGE_PATH" ]; then
    echo "${PACKAGE_NAME} already exists, replacing"
    rm -rf $PACKAGE_PATH
fi

task-start "Fetching ${PACKAGE_NAME}"
cmd=$( printf 'cd ~/catkin_ws/src/ && wget %q' "$1" ) || exit $?
runuser -l $(logname) -c "$cmd" || exit $?
task-done "Fetching ${PACKAGE_NAME}"

task-start "Converting to SSH access"
sed -i 's/https:\/\//git@/g' ${PACKAGE_PATH}
sed -i 's/\.com\//\.com:/g' ${PACKAGE_PATH}
sed -i 's/\.se\//\.se:/g' ${PACKAGE_PATH}
task-done "Converting to SSH access"

task-start "Installing packages"
cmd=$( printf 'cd ~/catkin_ws/src/ && vcs import --recursive --w 1 < %q' "${PACKAGE_NAME}" ) || exit $?
runuser -l $(logname) -c "$cmd" || exit $?
task-done "Installing packages"
