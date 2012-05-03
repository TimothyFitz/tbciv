#!/usr/bin/env python
import os
import signal
import subprocess
import time
import inspect

cwd = os.path.dirname(inspect.getfile(inspect.currentframe()))

def run(command, cwd=cwd):
    return subprocess.Popen(command.split(' '), cwd=cwd)#, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def main():
    run('twistd -n web --path .')
    run('sass --watch --style compressed scss:gen_css')
    run('coffee -o gen_js/ -cw src/')

    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print "Shutting down"

if __name__ == '__main__':
    main()
