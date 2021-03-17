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

apt-yes update || exit $?
apt-yes install busybox || exit $?

# rm -rf /etc/modprobe.d/blacklist-mttcan.conf

FILE=/enable_CAN.sh
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else 
    # Create enable_CAN.sh
    echo "$FILE does not exist, creating"
    echo '#!/bin/bash' > $FILE || exit $?
    echo 'sudo busybox devmem 0x0c303000 32 0x0000C400' >> $FILE || exit $?
    echo 'sudo busybox devmem 0x0c303008 32 0x0000C458' >> $FILE || exit $?
    echo 'sudo busybox devmem 0x0c303010 32 0x0000C400' >> $FILE || exit $?
    echo 'sudo busybox devmem 0x0c303018 32 0x0000C458' >> $FILE || exit $?
    echo 'sudo modprobe can' >> $FILE || exit $?
    echo 'sudo modprobe can_raw' >> $FILE || exit $?
    echo 'sudo modprobe mttcan' >> $FILE || exit $?
    echo 'sudo ip link set can0 type can bitrate 1000000 restart-ms 1000 sample-point 0.875 fd off' >> $FILE || exit $?
    echo 'sudo ip link set can0 up' >> $FILE || exit $?
    echo 'exit 0' >> $FILE || exit $?
    chmod 755 /enable_CAN.sh || exit $?
fi

FILE2=/etc/rc.local
if [ -f "$FILE2" ]; then
    echo "$FILE2 exists, inserting"
    sed -i "`wc -l < $FILE2`i\\sh /enable_CAN.sh &\\" $FILE2 || exit $?
else 
    echo "$FILE2 does not exist, creating"
    echo '#!/bin/bash' > $FILE2 || exit $?
    echo 'sh /enable_CAN.sh &' >> $FILE2 || exit $?
    echo 'exit 0' >> $FILE2 || exit $?
fi

chmod +x $FILE2 || exit $?

echo Success! ["$(basename $0)"]
