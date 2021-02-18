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

if [ -z ${1+x} ]; then
    echo "username is unset";
    TARGET_USER=$(logname)
else
    echo "username is set to '$1'";
    TARGET_USER=$1
fi

TARGET_DIR=/home/${TARGET_USER}/

task-start "Clone repos"
cmd=$( printf 'cd %q && git clone https://github.com/LSTS/neptus.git' "${TARGET_DIR}" ) || exit $?
runuser -l ${TARGET_USER} -c "$cmd" || exit $?

cmd=$( printf 'cd %q && git clone https://github.com/smarc-project/imc_ros_bridge.git' "${TARGET_DIR}" ) || exit $?
runuser -l ${TARGET_USER} -c "$cmd" || exit $?
task-done "Clone repos"

task-start "Move vehicle definitions"
for d in ${TARGET_DIR}imc_ros_bridge/neptus_vehicle_definitions/*/ ; do
    echo "copying $d"
	cp -ap $d. ${TARGET_DIR}neptus/vehicles-files/ || exit $?
done

CONF_ARRAY=(`find ${TARGET_DIR}neptus/vehicles-files/ -maxdepth 1 -name "*.nvcl"`)
if [ ${#CONF_ARRAY[@]} -gt 0 ]; then
    echo "vehicles found"
fi

for i in "${CONF_ARRAY[@]}"
do
	mv $i ${TARGET_DIR}neptus/vehicles-defs/ || exit $?
done
task-done "Move vehicle definitions"

task-start "Install java"
apt-yes install openjdk-8-jdk || exit $?
task-done "Install java"

task-start "Compile neptus"
cmd=$( printf 'cd %qneptus && ./gradlew' "${TARGET_DIR}" ) || exit $?
runuser -l ${TARGET_USER} -c "$cmd" || exit $?
task-done "Compile neptus"

task-start "Cleanup"
rm -rf ${TARGET_DIR}imc_ros_bridge/ || exit $?
task-done "Cleanup"

echo Success! ["$(basename $0)"]
