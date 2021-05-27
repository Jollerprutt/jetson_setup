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

task-start "Install ROS"
export ROS_DISTRO=melodic
# Setup sources
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' || exit $?

# Setup keys
sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 || exit $?

apt-yes update || exit $?
apt-yes install ros-${ROS_DISTRO}-desktop || exit $?

cmd=$( printf 'echo "source /opt/ros/%q/setup.bash" >> ~/.bashrc' "${ROS_DISTRO}" ) || exit $?
runuser -l ${TARGET_USER} -c "$cmd" || exit $?
runuser -l ${TARGET_USER} -c 'source ~/.bashrc' || exit $?

apt-yes install \
    python-rosdep \
    python-rosinstall \
    python-rosinstall-generator \
    python-wstool \
    build-essential \
    python-rosdep \
    || exit $?

rosdep init
runuser -l ${TARGET_USER} -c 'rosdep update' || exit $?

task-done "Install ROS"

task-start "Setup catkin"
runuser -l ${TARGET_USER} -c 'echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc' || exit $?
runuser -l ${TARGET_USER} -c 'mkdir -p ~/catkin_ws/src' || exit $?
apt-yes install python-catkin-tools || exit $?
runuser -l ${TARGET_USER} -c "cd ~/catkin_ws/ && catkin build"

task-done "Setup catkin"

task-start "Install SMaRC dependencies"
apt-yes install \
    python3-vcstool \
    libsdl2-dev \
    libglew-dev \
    libfreetype6-dev \
    ros-${ROS_DISTRO}-rosmon \
    ros-${ROS_DISTRO}-py-trees-ros \
    ros-${ROS_DISTRO}-tf2-geometry-msgs \
    ros-${ROS_DISTRO}-pid \
    ros-${ROS_DISTRO}-geographic-info \
    ros-${ROS_DISTRO}-nmea-navsat-driver \
    ros-${ROS_DISTRO}-robot-localization \
    ros-${ROS_DISTRO}-sbg-driver \
    ros-${ROS_DISTRO}-rosbridge-suite \
    ros-${ROS_DISTRO}-ddynamic_reconfigure_python \
    || exit $?

task-done "Install SMaRC dependencies"

echo Success! ["$(basename $0)"]
