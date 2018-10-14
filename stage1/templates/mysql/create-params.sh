#!/bin/bash

if [ -f mysql-params.json.orig ]; then
    mv mysql-params.json.orig mysql-params.json
fi

DATA=`base64 -w 0 mysql-cloud-init.yml`
sed -i '.orig' -e "s/TOBEFILLED/`echo $DATA`/" mysql-params.json 
