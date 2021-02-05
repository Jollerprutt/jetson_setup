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

# Create ssh directory if missing
runuser -l $(logname) -c 'cd && mkdir -p .ssh/' || exit $?

# Create known hosts file if missing
runuser -l $(logname) -c 'cd .ssh/ && touch known_hosts' || exit $?

FILE=/home/$(logname)/.ssh/id_ed25519
if [ -f "$FILE" ]; then
    echo "SSH keys already setup!"
    exit
fi
FILE2=/home/$(logname)/.ssh/id_rsa
if [ -f "$FILE2" ]; then
    echo "SSH keys already setup!"
    exit
fi

CONF_ARRAY=(`find $PARENT_DIR/ssh_keys_host/ -maxdepth 1 -name "id_*"`)
if [ ${#CONF_ARRAY[@]} -gt 0 ]; then
    echo "SSH key(s) found"
else
    echo "No SSH key(s) found, generating"
    cmd=$( printf 'ssh-keygen -t ed25519 -N "" -C "%q" -f %q/ssh_keys_host/id_ed25519' "${HOSTNAME}" "${PARENT_DIR}" ) || exit $?
    runuser -l $(logname) -c "$cmd" || exit $?

    echo "#############################################################################################"
    echo "########################### SSH Public key. Please add to github! ###########################"
    echo "#############################################################################################"
    cat ${PARENT_DIR}/ssh_keys_host/id_ed25519.pub
    echo "#############################################################################################"
    echo
    echo "Press any key to continue"
    echo

    secs=$((120))
    while (( $secs > 0 )); do
    echo -ne "Continuing in: $secs\033[0K\r"
    read -t 1 -n 1
    if [ $? = 0 ] ; then
        secs=0 ;
    fi
    : $((secs--))
    done
    echo
fi
exit

for i in "${CONF_ARRAY[@]}"
do
    FILE_NAME=$(basename $i)

    case "$FILE_NAME" in
    *.pub ) 
        # Public
        echo "Key [$FILE_NAME] found, moving to ~/.ssh/"
        mv $i /home/$(logname)/.ssh/ || exit $?
        # echo "Key is public"
        ;;
    *.*)
        # Unknown
        echo "Unknown file [$FILE_NAME] found, ignoring"
        ;;
    *)
        # Private
        echo "Key [$FILE_NAME] found, moving to ~/.ssh/"
        mv $i /home/$(logname)/.ssh/ || exit $?
        echo "Key is private, adding to agent"
        eval "$(ssh-agent -s)" || exit $?
        ssh-add /home/$(logname)/.ssh/$FILE_NAME
        ;;
    esac
done

echo Success! ["$(basename $0)"]
