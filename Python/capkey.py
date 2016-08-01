#!/usr/bin/python
import socket
import sys


meusocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

if meusocket.connect_ex((sys.argv[1], int(sys.argv[2]))) == 0:
    print "Conectado!", meusocket.recv(1024)
    meusocket.close()
