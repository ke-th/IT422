#!/usr/bin/env python

import socket
import os
import datetime
import csv
import time

def writelog(loginfo):
    now=datetime.datetime.now()
    logfile='CTF1.csv'
    try:
        logging=open(logfile, 'a')
    except:
        logging=open(logfile, 'w+')
    logging.write(now.strftime("%Y%m%d%H%M")+','+str(loginfo)+'\n')
    logging.close()

def main():
    TCP_IP = '192.168.3.200'
    TCP_PORT = 555
    BUFFER_SIZE = 1024
    MESSAGE = str(os.getpid())
    writelog(MESSAGE)
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((TCP_IP, TCP_PORT))
            s.send(MESSAGE)
            data = s.recv(BUFFER_SIZE)
            print "received data:", data
            writelog(data)
            s.close()
        except:
            writelog('heartbeat failed')
            
        time.sleep(120)

        


if __name__ == '__main__':
  main()
