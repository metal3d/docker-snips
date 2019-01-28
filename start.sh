#!/bin/bash
SEOPT=""
PRIV=""
selinuxenabled 2>&1 >/dev/null && SEOPT=":Z" && PRIV="--privileged"

function _start_snips_pulse() {
    DOCKERIP=$(ip -4 -o a| grep docker0 | awk '{print $4}' | cut -d/ -f1)
    mod=$(pactl load-module module-native-protocol-unix socket=/tmp/pulse.sock)

    docker run --rm -it \
        --name snips \
        -v $1:/usr/share/snips/assistant$SEOPT \
        -v /tmp/pulse.sock:/tmp/pulse.sock \
        -e USERID=$(id -u) \
        -e GROUPID=$(id -g) $PRIV \
        metal3d/snips

    pactl unload-module $mod

}


_start_snips_pulse $1

