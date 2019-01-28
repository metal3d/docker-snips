#!/bin/bash
SEOPT=""
PRIV=""

# Fedora, CentOS, and so on... needs some option to allow
# container to hit local volumes
selinuxenabled 2>&1 >/dev/null && SEOPT=":Z" && PRIV="--privileged"

PAMODULE='/var/tmp/snips-pa-module'

function unload_pa_module(){
    # if snips-pa-module file exists, stop the module and remove
    # the tmp file
    [ -f $PAMODULE ] && pactl unload-module $(cat $PAMODULE) && rm -f $PAMODULE

    # be sure pulse is alerted
    sleep 1
}


function load_pa_module(){
    # unload previous module, then reload

    unload_pa_module
    mod=$(pactl load-module module-native-protocol-unix socket=/tmp/pulse.sock)

    # save the module id in tmp path
    echo "$mod" > $PAMODULE
}

function _start_snips_pulse() {
    # load pulseaudio socket
    load_pa_module

    # start docker container
    docker run --rm -it \
        --name snips \
        -v $1:/usr/share/snips/assistant$SEOPT \
        -v /tmp/pulse.sock:/tmp/pulse.sock \
        -e USERID=$(id -u) \
        -e GROUPID=$(id -g) $PRIV \
        metal3d/snips

    # stop unix socket
    unload_pa_module

}

if [ "$1" == "" ]; then
    echo "$(basename $0) /path/to/you/assistant_dir"
    exit 1
fi


RP=$(realpath $1)

if [ ! -d $RP ]; then
    echo "$1 not found..."
    exit 1
fi

if [ ! -f $RP/assistant.json ]; then
    echo "$1 seems to not be an assitant directory (assistant.json file not found)"
    exit 1
fi

_start_snips_pulse $RP 

