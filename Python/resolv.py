#!/usr/bin/python
import socket
import sys

print sys.argv[1], "====>", socket.gethostbyname(sys.argv[1])
