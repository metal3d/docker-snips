
FROM debian:stretch-slim

RUN set -xe; \
    apt update; \
    apt install -y gnupg2 dirmngr apt-transport-https; \
    apt clean

RUN set -xe; \
    sed -i "s/ main/ main non-free/g" /etc/apt/sources.list; \
    echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list; \
    bash -c "apt-key adv --keyserver pool.sks-keyservers.net --recv-keys F727C778CCB0A455" ; \
    apt update; \
    apt install -y pulseaudio snips-platform-voice snips-skill-server curl unzip git python3 python3-virtualenv python3-pip; \
    apt clean

RUN set -xe; \
    useradd -m user;

# ENV PULSE_SERVER /run/pulse/native
# RUN echo "enable-shm=no" >> /etc/pulse/client.conf
RUN set -xe; \
    echo "default-server = unix:/tmp/pulse.sock" > /etc/pulse/client.conf; \
    echo "autospawn = no" >> /etc/pulse/client.conf; \
    echo "daemon-binary = /bin/true" >> /etc/pulse/client.conf; \
    echo "enable-shm = false" >> /etc/pulse/client.conf; \
    # echo "default-sample-rate = 44100" >> /etc/pulse/daemon.conf; \
    usermod -g pulse-access _snips; \
    usermod -g pulse-access user; 

ADD snips.toml /etc/snips.toml
ADD entrypoint.sh /entrypoint.sh

ENV PULSE_SERVER "unix:/tmp/pulse.sock"
ENV PULSE_COOKIE "/tmp/pulse.cookie"

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

