# Using Snips with sound on Docker

This project provides scripts and Dockerfiles to be able to launch [Snips](https://snips.ai/) on a Docker environment **without the need of satelites sound input** - so you will be able to launch Snips assistant on any Linux distribution.

This project is inspired from the great work of [dYalib](https://github.com/dYalib) in his repository: https://github.com/dYalib/snips-docker

## Prepare an assistant

First, go to snips.ai website and subscribe or login. Create an assistant and some intents.

Afterward, you can "download" your assistant following the "deploy assistant" link and choosing "download". You will reveive a zip file that you can unpack somewhere on your local machine.

## Launching Snips

There is a "`start.sh`" script that helps to start the container. It automatically load pulseaudio module, start the container and stop module if needed.

```bash
./start.sh /path/to/your/assistant
```

Several options are now added, see the help options `-h`:

```

start.sh [OPTS] <assistant_dir>

<assistant_dir> must be a downloaded assistant from https://snip.ia dashboard, it contains assistant.json file.

Optional options:

-s|--skills     Path to skills to install and launch
-d|--devel      Path to your local skill your are developping
                This allows you to start your setup environement and skill script manually.
                Your development directory will reside in /home/user/dev directory.
-h|--help       This help.

```

If you provide a skill directory, so the container will try to install the skills inside the `/var/lib/snips/skills directory`.

If you provide a dev directory, it will be mounted inside `/home/user/dev`.

**VERY IMPORTANT** : After you launched the container, if you want to start development script, **change user to "user"** `su -l user`, if you don't do that, generated files (as venv or .pyc files) will be owned by "root" - I'm trying to avoid that.

To launch a development environement:

```bash
./start.sh -d ~/Project/snips/myproject ~/Project/snips/assistant
# snips logs will appear...

# in another terminal
$ docker exec -it snips bash
(in container) $ su -l user
(in container) $ cd dev
# remove venv if you want to restart setup, then
(in container) $ ./setup.sh
(in container) $ source venv/bin/activate
(in container) (venv) $ python your_action.py
```


## If you want to launch it manually

For several reason, we need to have the same user id and groupe id inside the container than yours on host machine. So, you will need to use:

- `-e USERID=$(id -u)`
- `-e GROUPID=$(id -g)`

It's important for Pulseaudio !

You **must** mount your assistant inside the container. Here is an example:

You need to share you host pulseaudio server with container. In a terminal:

```bash
pactl load-module module-native-protocol-unix socket=/tmp/pulse.sock
```

Then, you can share the socket to container by mounting `/tmp/pulse.sock` as a volume in the container.

```bash
docker run --rm -it \
    -v /path/to/your/assistant:/usr/share/snips/assistant:ro \
    -e USERID=$(id -u) -e GROUPID=$(id -g) \
    -v /tmp/pulse.sock:/tmp/pulse.sock \
    metal3d/snips
```

It could take a while before pulseaudio becomes available in certain case. If snips doesn't hear your hotword ("hey snips !"), check in audio configuration in the "applications" tab if snips-audio-server appears.


# Deploy skills

## local skills
You can deploy local skills using the `/home/user/deploy` directory where you can mount sources. This will **copy** sources inside `/var/lib/snips/skills` directory and launch install process (using `setup.sh`) before to start snips.

This is the recommended way to install skills if you're not developping.

## develop skills and launch them manually
Anyway, you can manually launch setup and skills in another directory to develop and test a snip skill. For example:

```bash
$ docker run --rm -it --name snips ... -v $PWD/myskill:/home/user/myskill
$ docker exec -it snips bash
 (in snips container) $ su -l user
 (in snips container) $ cd myskill
 (in snips container) $ ./setup
 (in snips container) $ source venv/bin/activate
 (in snips container) (venv) $ python myskill/main.py
```

You will be able to use docker-compose to mount sources, restart container, make tests... and so on.


