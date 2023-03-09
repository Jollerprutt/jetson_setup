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

if [ "$UBUNTU_VERSION" == "20.04" ];
then
        echo "ROS set to Noetic"
        export ROS_DISTRO=noetic
else
        echo "Assuming melodic"
        export ROS_DISTRO=melodic
fi

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
    SAVE_HOME=$(echo $HOME)
    HOME=/home/root
    pip install -U jetson-stats || exit $?
    HOME=$SAVE_HOME
    task-done "Install Jetson-stats"
fi

task-start "Install sam_robot packages"
$SCRIPT_DIR/rosinstall.sh https://raw.githubusercontent.com/smarc-project/rosinstall/master/sam_robot.rosinstall || exit $?
task-done "Install sam_robot packages"

task-start "Configure uavcan_ros_bridge"
runuser -l $(logname) -c 'cd ~/catkin_ws/src/uavcan_ros_bridge/ && git submodule update --init --recursive' || exit $?
cd /home/$(logname)/catkin_ws/src/uavcan_ros_bridge/uavcan_ros_bridge/libuavcan/libuavcan/dsdl_compiler/pyuavcan && python setup.py install || exit $?
task-done "Configure uavcan_ros_bridge"

task-start "Fetch cola2_msgs"
runuser -l $(logname) -c 'cd ~/catkin_ws/src/ && git clone https://bitbucket.org/iquarobotics/cola2_msgs.git' || exit $?
task-done "Fetch cola2_msgs"

task-start "Fetch sam sbg config"
SBG_CONF_DIR=/opt/ros/${ROS_DISTRO}/share/sbg_driver/config
if [ -d "$SBG_CONF_DIR" ];
then
    if [ ! -f "$SBG_CONF_DIR/ellipse_A_sam.yaml" ]; then
        echo "sbg configuration missing, fetching"
        cd $SBG_CONF_DIR && wget https://raw.githubusercontent.com/smarc-project/sbg_ros_driver/noetic-devel/config/ellipse_A_sam.yaml || exit $?
    else
        echo "sbg configuration already present"
    fi
else
    echo "sbg driver missing"
fi
task-done "Fetch sam sbg config"

task-start "Install scipy"
apt-yes update || exit $?
apt-yes install python3-scipy || exit $?
task-done "Install scipy"

task-start "Install vision-msgs"
apt-yes update || exit $?
apt-yes install ros-melodic-vision-msgs || exit $?
task-done "Install vision-msgs"

# task-start "Catkin build"
# runuser -l $(logname) -c 'source ~/.bashrc && cd ~/catkin_ws/ && catkin clean --yes && catkin build' || exit $?
# task-done "Catkin build"

echo Success! ["$(basename $0)"]
