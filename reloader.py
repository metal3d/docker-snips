#!/usr/bin/env python3
import os
from os.path import getmtime
import time
import subprocess
import sys

FILTERS = ['.swp']


def get_mtime(directory):
    def _yield():
        for dirname, _, files in os.walk('.'):
            for fname in files:
                fpath = os.path.join(dirname, fname)
                ext = '.' + fpath.split('.')[-1]
                if ext in FILTERS:
                    continue
                try:
                    t = getmtime(fpath)
                    yield t
                except FileNotFoundError:
                    continue
    return _yield()


def launch(command):
    command = ' '.join(command)
    process = subprocess.Popen(
            command,
            stdout=sys.stdout,
            stderr=sys.stderr,
            shell=True)
    return process


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("You must provide a command")
        sys.exit(1)

    try:
        process = launch(sys.argv[1:])
        mtime = max(get_mtime('.'))
        while True:
            time.sleep(1)
            newtime = max(get_mtime('.'))
            if newtime > mtime:
                print("Reload")
                mtime = max(get_mtime('.'))
                process.terminate()
                process.kill()
                process = launch(sys.argv[1:])
    except KeyboardInterrupt:
        process.terminate()
        process.kill()
        print('Done')
