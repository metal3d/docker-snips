FROM debian:stretch-slim

RUN set -xe; \
    apt update; \
    apt install -y gnupg2 dirmngr apt-transport-https; \
    sed -i "s/ main/ main non-free/g" /etc/apt/sources.list; \
    \
    : sometimes fails... retry twice; \
    echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list || \
    sleep 1 &&  \
    echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list ; \
    bash -c "apt-key adv --keyserver pool.sks-keyservers.net --recv-keys F727C778CCB0A455" ; \
    apt update; \
    apt install -y pulseaudio snips-platform-voice snips-skill-server curl unzip git python3 python3-venv python3-pip \
        python python-virtualenv python-pip \
        supervisor; \
    apt clean

ENV PULSE_SERVER "unix:/tmp/pulse.sock"
ENV PULSE_COOKIE "/tmp/pulse.cookie"

RUN set -xe; \
    useradd -m -s /bin/bash user;

RUN set -xe; \
    echo "default-server = unix:/tmp/pulse.sock" > /etc/pulse/client.conf; \
    echo "autospawn = no" >> /etc/pulse/client.conf; \
    echo "daemon-binary = /bin/true" >> /etc/pulse/client.conf; \
    echo "enable-shm = false" >> /etc/pulse/client.conf; \
    # echo "default-sample-rate = 44100" >> /etc/pulse/daemon.conf; \
    usermod -g pulse-access _snips; \
    usermod -g pulse-access user; 



ADD ./snips.conf /etc/supervisor/conf.d/snips.conf
ADD snips.toml /etc/snips.toml

ENV PORT 1883
RUN sed -i "s/@PORT@/${PORT}/" /etc/snips.toml 
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

