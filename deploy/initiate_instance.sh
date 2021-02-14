#!/bin/bash

cd ${SEQR_DIR}/

echo 'running seqr instance startup scripts. Make sure to check log files for confirmation of successful setup'

#start postgresql service
echo 'starting postgresql'
sudo service postgresql restart

echo 'starting elasticsearch'
./${SEQR_DIR}/elasticsearch-7.10.2/start_elasticsearch.sh

echo 'starting kibana'
./${SEQR_DIR}/kibana-7.10.2-linux-x86_64/start_kibana.sh

echo 'starting redis'
./${SEQR_DIR}/redis/start_redis.sh

echo 'starting gunicorn'
./start_server.sh

echo 'done'
