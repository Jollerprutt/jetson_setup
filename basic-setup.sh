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

#task-start "Prevent OTA updates of bootloader & kernel"
#apt-mark hold nvidia-l4t-bootloader nvidia-l4t-kernel nvidia-l4t-kernel-dtbs nvidia-l4t-kernel-headers
#task-done "Prevent OTA updates of bootloader & kernel"

UBUNTU_VERSION="$(lsb_release -rs)" || exit $?

task-start "Install tmux"
apt-yes update || exit $?
apt-yes install tmux || exit $?
task-done "Install tmux"

task-start "Add $(logname) to dialout"
gpasswd -a $(logname) dialout || exit $?
task-end "Add $(logname) to dialout"

task-start "Prepare tmux"
runuser -l $(logname) -c 'tmux new-session -d -s jetson_setup' || exit $?
cmd=$( printf 'tmux send-keys "cd %q/scripts" C-m' "${SCRIPT_DIR}" ) || exit $?
runuser -l $(logname) -c 'tmux send-keys "clear" C-m' || exit $?
runuser -l $(logname) -c "$cmd" || exit $?
runuser -l $(logname) -c 'tmux send-keys "sudo ./tmux-setup.sh" C-m' || exit $?
task-done "Prepare tmux"

echo Script finished successfully! ["$(basename $0)"]
echo "Continuing in tmux"
runuser -l $(logname) -c 'tmux attach-session -t jetson_setup'
