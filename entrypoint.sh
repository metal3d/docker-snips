#!/bin/bash

eval $(fixuid -q)


_skill=0

# deploy given skills
if [ -d /home/user/deploy ] ; then
    _skill=1
    cp -r /home/user/deploy/* /var/lib/snips/skills/

    for d in $(find /var/lib/snips/skills -maxdepth 1 -type d); do
        pushd $d
            echo "Deploying in $d"
            [ -f setup.sh ] && bash setup.sh
        popd
    done
fi

# start mosquitto at a certain port
mosquitto -d -p $PORT 2>&1 1>/dev/null


# start supervisord to launch snips services
supervisord 2>&1 1>/dev/null 
if [ $? != 0 ]; then
    echo "Supervisord failed to start"
    exit 1
fi

if [ $_skill -eq 1 ]; then
    echo "Launching skill-server"
    nohup snips-skill-server &
    sleep 1
fi

if [ "$1" == "" ]; then
    tail -f /var/log/supervisor/snips*.log 
    exit 0
fi

exec $@

