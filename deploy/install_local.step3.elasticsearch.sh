#!/usr/bin/env bash

VERSION=7.6.0

set +x
set +x
echo
echo "==== Install and start elasticsearch ====="
echo
set -x

cd ${SEQR_DIR}
wget -nv https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}-linux-x86_64.tar.gz
tar xzf elasticsearch-${VERSION}-linux-x86_64.tar.gz
rm elasticsearch-${VERSION}-linux-x86_64.tar.gz
cd elasticsearch-${VERSION}

echo '
cd '$(pwd)'
LOG_FILE=$(pwd)/elasticsearch.log
(ES_JAVA_OPTS="-Xms3900m -Xmx3900m" nohup ./bin/elasticsearch -E network.host=0.0.0.0 >& ${LOG_FILE}) &
sleep 7;
curl http://localhost:9200
echo "Elasticsearch started in background. See ${LOG_FILE}"
' | tee start_elasticsearch.sh
chmod 777 ./start_elasticsearch.sh

set +x

./start_elasticsearch.sh

cd  ..
