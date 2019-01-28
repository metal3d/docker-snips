.PHONY: pulse

all: pulse

pulse:
	docker build -t metal3d/snips . 

