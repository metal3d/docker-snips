.PHONY: pulse alsa

all: pulse alsa

pulse:
	docker build -t metal3d/snips . 

