#!/usr/bin/env bash

unset INFORM_HOST
unset UNIFI_DEVICE

SCRIPT_FULL_PATH=$(realpath ${0})
SCRIPT_FILENAME=$(basename ${0})
SCRIPT_FRIENDLY_NAME=${SCRIPT_FILENAME%.*}

USAGE=$(cat <<EOF
Usage: ${SCRIPT_FILENAME} INFORM_HOST [UNIFI_DEVICE]
EOF
)

INFORM_HOSTS=$(cat <<EOF
10.0.253.5
192.168.1.10
ubnt.home.dev
EOF
)

UNIFI_DEVICES=$(cat <<EOF
192.168.1.1
192.168.1.100
192.168.1.101
192.168.1.102
192.168.1.103
EOF
)

if [ ${EUID} -eq 0 ]; then
    echo "Please run this script as a non-root user."
    echo ${USAGE}
    exit 1
fi

if [ -z ${1} ]; then
    printf "Invalid options. "
    echo ${USAGE}
    exit 1
else
    for HOST in ${INFORM_HOSTS}; do
        if [[ ${1} = ${HOST} ]]; then
            INFORM_HOST=${HOST}
        fi
    done

    if [ -z ${INFORM_HOST} ]; then
        printf "Invalid options. "
	echo ${USAGE}
	echo ""
        echo "Valid INFORM_HOST options are:"
	printf '%s\n' "${INFORM_HOSTS[@]}" | sort
        exit 1
    fi
fi

if [ ! -z ${2} ]; then
    for DEVICE in ${UNIFI_DEVICES}; do
        if [[ ${2} = ${DEVICE} ]]; then
            UNIFI_DEVICE=${DEVICE}
	fi
    done

    if [ -z ${UNIFI_DEVICE} ]; then
        printf "Invalid options. "
	echo ${USAGE}
	echo ""
        echo "Valid UNIFI_DEVICE options are:"
	printf '%s\n' "${UNIFI_DEVICES[@]}" | sort
	exit 1
    fi
fi

if [ $(which tmux | wc -l) -gt 0 ]; then
    if [ -z ${TMUX} ]; then
        if [ $(tmux ls 2> /dev/null | grep -wc ${SCRIPT_FRIENDLY_NAME}) -eq 0 ]; then
            tmux new -s ${SCRIPT_FRIENDLY_NAME} ${SCRIPT_FULL_PATH} ${@}
	    exit 0
        else
            tmux attach -t ${SCRIPT_FRIENDLY_NAME}
	    exit 0
        fi
    fi
else
    echo "Consider installing tmux for better session control, continuing..."
fi

if [ -z ${UNIFI_DEVICE} ];then
    for UNIFI_DEVICE in $(echo "$UNIFI_DEVICES" | sort -r); do
        echo "Informing ${UNIFI_DEVICE} (${INFORM_HOST})"
	ssh ${UNIFI_DEVICE} "mca-cli-op set-inform http://${INFORM_HOST}:8080/inform"
    done

    echo "Exiting..."
    sleep 1
else
    ssh ${UNIFI_DEVICE} "mca-cli-op set-inform http://${INFORM_HOST}:8080/inform"
    sleep 5
    ssh ${UNIFI_DEVICE} "mca-cli-op set-inform http://${INFORM_HOST}:8080/inform"
fi

if [ $(tmux list-clients | wc -l) -gt 0 ]; then
    echo ""
    read -p "Operation complete, press [enter] to continue "
fi
