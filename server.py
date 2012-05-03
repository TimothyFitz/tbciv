#!/usr/bin/env python
import os
import signal
import subprocess
import time
import inspect

cwd = os.path.dirname(inspect.getfile(inspect.currentframe()))

def run(command, cwd=cwd):
    return subprocess.Popen(command.split(' '), cwd=cwd)#, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def nginx():
    return run('python nginx.py')

def solr():
    return run('./run_solr.sh')

def sass():
    return run('sass --watch --style compressed static/scss:static/css')

def main():
    run('twistd -n web --path .')
    run('sass --watch --style compressed scss:css')
    run('coffee -o gen_js/ -cw src/')

    while True:
        time.sleep(10)

    
if __name__ == '__main__':
    main()
