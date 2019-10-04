FROM debian:stretch-slim

LABEL maintainer="Patrice Ferlet <metal3d@gmail.com>" \
      snips.version="1.3.0 (0.64.0)"

RUN set -xe; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg2 dirmngr apt-transport-https; \
    sed -i "s/ main/ main non-free/g" /etc/apt/sources.list; \
    echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list; \
    : "Loop until it works... "; \
    COUNT=0; \
    while true ; do \
        apt-key adv --keyserver pool.sks-keyservers.net --recv-keys F727C778CCB0A455 && break || sleep 1; \
        COUNT=$((COUNT+1)) && [ "$COUNT" -gt 10 ] && exit 1; \
    done; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        pulseaudio snips-platform-voice snips-skill-server curl unzip git python3-dev python3-venv python3-pip \
        python-dev python-virtualenv python-pip \
        supervisor; \
    apt-get clean

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
    usermod -g _snips user

ADD reloader.py /usr/local/bin/reloader

# FIXUID - My god... What a tool...
RUN USER=user && \
    GROUP=user && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml; \
    echo "paths:" >> /etc/fixuid/config.yml; \
    echo "  - /var/lib/snips" >> /etc/fixuid/config.yml;

ADD supervisord.conf /etc/supervisor/supervisord.conf
RUN mkdir -p /var/lib/snips && chown -R user:user /var/lib/snips/skills /var/log/supervisor*

ADD ./snips.conf /etc/supervisor/conf.d/snips.conf
ADD snips.toml /etc/snips.toml

ENV PORT 1883
RUN sed -i "s/@PORT@/${PORT}/" /etc/snips.toml 
ADD entrypoint.sh /entrypoint.sh

USER 1000:1000
WORKDIR /home/user/dev
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

