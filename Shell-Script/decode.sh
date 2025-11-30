#!/bin/bash
if [ $# != 1 ]; then
	echo -e "Usage ./decode.sh <number of loop>"
	exit 0
fi

x=1
cat teste.txt > temp.txt
while [ $x -le $1 ]; do
	cat temp.txt | base64 --d > temp1.txt
	x=$(($x+1))
	cat temp1.txt > temp.txt
done
cat temp.txt
echo " "
