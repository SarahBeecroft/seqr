#!/usr/bin/env bash

cd ${SEQR_DIR}/phenotips-standalone-1.2.6

echo 'cd '$(pwd)'
LOG_FILE=$(pwd)/phenotips.log
(nohup ./start.sh >& ${LOG_FILE}) &
echo "PhenoTips started in background on port 8080. See ${LOG_FILE}"
' | tee start_phenotips.sh

chmod 777 start_phenotips.sh

./start_phenotips.sh
