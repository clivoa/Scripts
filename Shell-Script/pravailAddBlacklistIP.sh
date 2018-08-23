#!/bin/bash

url_para_bloquear=`cat $1`

for i in ${url_para_bloquear}
do
    echo "curl -s -k -X POST -H 'X-Arbux-APIToken: 27vjGN_kDrjCsAzXZsD2Zlx3kFyJ3TNUku9HAnGM' -H 'Accept : application/json' https://172.18.128.150/api/aps/v1/protection-groups/blacklisted-domains/?domain="${i} | sh
    sleep 2s
done
