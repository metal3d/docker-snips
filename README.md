# Using Snips with sound on Docker

This project provides scripts and Dockerfiles to be able to launch [Snips](https://snips.ai/) on a Docker environment **without the need of satelites sound input** - so you will be able to launch Snips assistant on any Linux distribution.

This project is inspired from the great work of [dYalib](https://github.com/dYalib) in his repository: https://github.com/dYalib/snips-docker

This image uses `fixuid` https://github.com/boxboat/fixuid that allow us to bind local host user id to the container user ID.

And there is a "reloader" tool to auto-restart your development skills while you're writing code. See below.

## Prepare an assistant

First, go to https://snips.ai website and subscribe or login. Create an assistant and some intents.

Afterward, you can "download" your assistant following the "deploy assistant" link and choosing "download". You will reveive a zip file that you can unpack somewhere on your local machine.

## Launching Snips

There is a "`start.sh`" script that helps to start the container. It automatically loads pulseaudio module, starts the container and stops module if needed when you exit container.

```bash
./start.sh /path/to/your/assistant [OPTS] [command]

# examples
## start snips and open a bash terminal
./start.sh ../assistant bash

## start snips without a terminal
./start.sh ../assitant

## start snips with a development dir from local directory
## skill is not launched, you can got to the container and launch the
## skill - for example
## 1 - start container
./start.sh ../assistant -d ./my_skill

## 2- then... install requirements and launch script
docker exec -it snips bash
./setup.sh
source venv/bin/activate
python3 your-app.py

## To start you skill as Snips will do it later:
./start.sh ../assistant -s ./my_skill

## => container starts, install skill and launch snips services + snips-skill-server

```

Several others options can help, see the help options `-h`:

```

start.sh [OPTS] <assistant_dir> [command]

<assistant_dir> must be a downloaded assistant from https://snip.ia dashboard, it contains assistant.json file.
[command] is a command to launch at startup, if no command is provided, the container will "tail" log files from
snips services.

Optional options:

-s|--skills     Path to skills to install - that will launch snips-skill-server after having deploy the skill
-d|--devel      Path to your local skill your are developping
                This allows you to start your setup environement and skill script manually.
                Your development directory will reside in /home/user/dev directory.
-h|--help       This help.

```

If you provide a skill directory, so the container will try to install the skills inside the `/var/lib/snips/skills` directory.

If you provide a dev diretory, it is mounted in `/home/user/dev` directory where you can setup and start python scripts. See next section that presents how to develop skills inside the container.

## Develop a skill

If you provide a dev directory, it will be mounted inside `/home/user/dev`.
To launch a development environement:

```bash
# launch snips and a bash session:
./start.sh -d ~/Project/snips/myproject ~/Project/snips/assistant
(in container) $

# OR withtout a bash session to see logs
./start.sh -d ~/Project/snips/myproject ~/Project/snips/assistant
# snips logs will appear...
# In that case, open another terminal and use
$ docker exec -it snips bash

# Then, to launch the script
(in container) $ cd dev
# remove venv if you want to restart setup, then
(in container) $ ./setup.sh
(in container) $ source venv/bin/activate
(in container) (venv) $ python your_action.py
```

## Auto reload while you're developing

There is a "reloader" program that checks if files are modified and restart the command that you want. It is very nice to not have to manually restart your development script while you're developing:

```bash
(in container) $ reloader python your_action.py
```

It checks each second if the file is modified, and terminate/kill the process to relaunch it. Note that this is a simple tool that can crash sometimes (I didn't have crash by my side, but if you get one, please report bug).



# If you want to launch it manually

For several reasonis, we need to have the same user id and group id inside the container than yours on host machine. So, you will need to use:

```
--user $(id -u):$(id -g)
# or direct id usage
--user 1000:1000
```

You need to share you host pulseaudio server with container. In a terminal:

```bash
# note the module id that will be displayed
pactl load-module module-native-protocol-unix socket=/tmp/pulse.sock
```

Then, you can share the socket to container by mounting `/tmp/pulse.sock` as a volume in the container.
You **must** mount your assistant inside the container.

```bash
docker run --rm -it \
    -v /path/to/your/assistant:/usr/share/snips/assistant:ro \
    --user $(id -u):$(id -g) \
    -v /tmp/pulse.sock:/tmp/pulse.sock \
    metal3d/snips
```

It could take a while before pulseaudio becomes available in certain cases. If snips doesn't hear your hotword ("hey snips !"), check in audio configuration in the "applications" tab if snips-audio-server appears.

When you want to unload the pulseaudio socket, use the given id while you loaded the module and use:
```
# where N is the id
pactl unload-module N
```

# Deploy skills

Work in progress - it only install the skills, they are not launched at this time.

You can deploy local skills using the `/home/user/deploy` directory where you can mount sources. This will **copy** sources inside `/var/lib/snips/skills` directory and launch install process (using `setup.sh`) before to start snips.

This is the recommended way to install skills if you're not developping.



