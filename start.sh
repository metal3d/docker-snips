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

    local assistant=$1
    local skills=$2
    local dev=$3
    local command=$4

    if [ "$skills" != "" ]; then
        skills=$(realpath $skills)
        bn=$(basename $skills)
        bn=$(echo "$bn" | sed 's/^snips-//')
        skills="-v $skills:/home/user/deploy/$bn$SEOPT"
    fi

    if [ "$dev" != "" ]; then
        dev=$(realpath $dev)
        dev="-v $dev:/home/user/dev$SEOPT"
    fi

    # load pulseaudio socket
    load_pa_module

    # start docker container
    docker run --rm -it \
        --name snips \
        -v $assistant:/usr/share/snips/assistant$SEOPT \
        -v /tmp/pulse.sock:/tmp/pulse.sock \
        $skills $dev \
        --user $(id -u):$(id -g) \
        -e USERID=$(id -u) \
        -e GROUPID=$(id -g) $PRIV \
        metal3d/snips $command

    # stop unix socket
    unload_pa_module
}


function usage() {
cat << EOF
$(basename $0) [OPTS] <assistant_dir> [command]

<assistant_dir> must be a downloaded assistant from https://snip.ia dashboard, it contains assistant.json file.
[command] is a command to launch at startup, if no command is provided, the container will "tail" log files from
snips services.

Optional options:

-s|--skills     Path to skills to install (not launched, work in progress)
-d|--devel      Path to your local skill your are developping
                This allows you to start your setup environement and skill script manually.
                Your development directory will reside in /home/user/dev directory.
-h|--help       This help.

EOF
}


s=""
d=""
p=""
command=""



OPTS=`getopt -o hd:s: --long help,devel:,skills: -n 'parse-options' -- "$@"`
eval set -- "$OPTS"

while true; do
case $1 in
    -h|--help)
        usage
        exit 0
        ;;
    -d|--devel)
        d=$2; shift; shift;
        ;;
    -s|--skills)
        s=$2; shift; shift;
        ;;
    --)
        shift; break
        ;;
esac
done

p=$1
command=$2

if [ "$p" == "" ]; then
    echo "$(basename $0) /path/to/you/assistant_dir"
    exit 1
fi


RP=$(realpath $p)

if [ ! -d $RP ]; then
    echo "$p not found..."
    exit 1
fi

if [ ! -f $RP/assistant.json ]; then
    echo "$1 seems to not be an assitant directory (assistant.json file not found)"
    exit 1
fi


for i in "$s" "$d"; do
    if [ "$i" != "" ] && [ ! -d $i ]; then
        echo "$i not found"
        exit 1
    fi
done


_start_snips_pulse "$RP" "$s" "$d" "$command"

