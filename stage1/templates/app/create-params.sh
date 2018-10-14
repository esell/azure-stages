#!/bin/bash

if [ -f app-params.json.orig ]; then
    mv app-params.json.orig app-params.json
fi

DATA=`base64 -w 0 app-cloud-init.yml`
sed -i '.orig' -e "s/TOBEFILLED/`echo $DATA`/" app-params.json 
