#!/bin/bash

function pull-start {
    echo -e "Starting \e[1;32m>>>\e[0m "$(basename $PWD)""
}

function pull-done {
    echo -e "Finished \e[32m<<<\e[0m"
}

echo -e "\e[1;33m>>> Pulling all repos\e[0m" || exit $?

for i in $(find ~/catkin_ws/src/ -maxdepth 2 -name ".git"); do
    cd "$(dirname "$i")" || exit $?

    pull-start
    git pull || exit $?
    pull-done
    # git status || exit $?
    echo "" || exit $?
done

echo -e "\e[1;33m<<< Done :)\e[0m" || exit $?
