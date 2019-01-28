#!/bin/bash

groupmod -g $GROUPID user
usermod -g $GROUPID -u $USERID user

# deploy given skills
if [ -d /home/user/deploy ] ; then
    cp -r /home/user/deploy/* /var/lib/snips/skills/

    for d in $(find /var/lib/snips/skills -maxdeph 1 -type d); do
        pushd $d
            echo "Deploying in $d"
            [ -f setup.sh ] && bash setup.sh
        popd
    done
fi

mosquitto -d

# wait ${PIDS[*]}
if [ "$@" != "" ]; then
    # allow starting a command line
    exec su -l user -c "
    snips-asr &
    snips-dialogue &
    snips-nlu &
    snips-audio-server &
    snips-hotword &
    snips-tts &
    $@"

else
    # CTRL + C stops the container as
    # the last service is stopped
    exec su -l user -c "
    snips-asr &
    snips-dialogue &
    snips-nlu &
    snips-audio-server &
    snips-hotword &
    snips-tts"
fi



