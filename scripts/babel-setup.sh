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

NUM=0
DEVICES="/dev/serial/by-id/*"
FILE=/enable_CAN.sh
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else 
    # Create enable_CAN.sh
    echo "$FILE does not exist, creating"
    echo '#!/bin/bash' > $FILE || exit $?
    for f in $DEVICES
    do
	    echo "Device $f"
	    if [[ $f == /dev/serial/by-id/usb-Zubax_Robotics_Zubax_Babel* ]];
	    then
		    echo "sudo slcand -o -s8 -t hw -S 3000000 $f can$NUM" >> $FILE || exit $?
		    sleep 1 || exit $?
		    echo "sudo ip link set up can$NUM" >> $FILE || exit $?
		    NUM=$(($NUM+1))
		    echo "babels found: $NUM"
	    fi
    done
    #echo 'sudo modprobe can' >> $FILE || exit $?
    #echo 'sudo modprobe can_raw' >> $FILE || exit $?
    #echo 'sudo modprobe mttcan' >> $FILE || exit $?
    #echo 'sudo ip link set can0 type can bitrate 1000000 restart-ms 1000 sample-point 0.875 fd off' >> $FILE || exit $?
    #echo 'sudo ip link set can0 up' >> $FILE || exit $?
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
