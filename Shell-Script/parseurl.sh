#!/bin/bash
if [ "$1" == "" ] then
	echo "Analisador de URL - Tarefa Modulo 3"
	echo "Exemplo de uso: $0 sitealvo.com.br"
else
	wget -q $1;
	grep -Eoi '<a [^>]+>' index.html | grep -Eo 'href="[^\"]+"' | grep -Eo '(http|https)://[^/"]+' | cut -d "/" -f3 | sort | uniq > lista.txt
    	for x in $(cat lista.txt); do
		host $x; done
	fi
rm -rf index.html lista.txt
