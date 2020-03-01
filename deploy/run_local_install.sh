#!/usr/bin/env bash

SEQR_INSTALL_BASE='/data'
SEQR_DIR='/data/seqr'
IP_ADDRESS=$(curl ifconfig.me)

#Install python 2.7: 

sudo apt-get update
sudo apt-get install -y python

#Install python pip and upgrade it

sudo -H apt-get install -y python-pip 
sudo -H pip2 install -y --upgrade pip

#Download the seqr repo
cd ${SEQR_INSTALL_BASE}
SCRIPT=seqr_dependencies.sh && \
   curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && \
   chmod 777 $SCRIPT && \ 
   ./$SCRIPT

#make elasticsearch directory
mkdir ${SEQR_DIR}/elasticsearch
cd ${SEQR_DIR}

#Create an bash variable, add it to ~/.bash_rc and run source ~/.bashrc

if [ -z "$SEQR_DIR"  ]; then

    export SEQR_DIR=/data/seqr
    export SEQR_BIN_DIR=${SEQR_DIR}/../bin
    cat <(echo 'export SEQR_DIR='${SEQR_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
    cat <(echo 'export SEQR_BIN_DIR='${SEQR_BIN_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
    cat <(echo 'export PATH='${SEQR_BIN_DIR}':$PATH') ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc

fi

source ~/.bashrc  

#Install seqr's python dependencies

cd ${SEQR_DIR}
sudo apt-get install -y python-psycopg2
sudo apt-get install -y libpq-dev
sudo apt remove -y python-psycopg2
sudo -H pip install -r ${SEQR_DIR}/requirements.txt

#Install tabix 
sudo apt-get install -y tabix

#Install MongoDB
sudo apt-get install -y mongodb

#Install Postgres 
sudo apt-get install postgresql postgresql-contrib

#Don't change the password to the postgres user, causes problems
#Edit /etc/postgresql/<version>/main/pg_hba.conf to change permission settings to make postgres work

PG_HBA_PATH=$(find /etc/postgresql -name "pg_hba.conf")
sudo sed -i s/peer/trust/ $PG_HBA_PATH
sudo sed -i s/md5/trust/ $PG_HBA_PATH

# should look like this when done
#    # Database administrative login by Unix domain socket
#    local   all             postgres                                trust
#    # TYPE  DATABASE        USER            ADDRESS                 METHOD
#    # "local" is for Unix domain socket connections only
#    local   all             all                                     trust
#    # IPv4 local connections:
#    host    all             all             127.0.0.1/32            trust
#    # IPv6 local connections:
#    host    all             all             ::1/128                 trust
#    # Allow replication connections from localhost, by a user with the
#    # replication privilege.
#    #local   replication     postgres                                peer
#    #host    replication     postgres        127.0.0.1/32            md5
#    #host    replication     postgres        ::1/128                 md5

#start postgresql service
sudo service postgresql restart

#Install the official Oracle Java Development kit 8 (JDK v1.8) for PhenoTips to work properly. 
#Don't get the java runtime enviornment (JRE), it's not enough.

sudo apt-get update
sudo apt install -y openjdk-8-jre

#Install PhenoTips 

cd ${SEQR_DIR}
sudo apt-get install -y unzip

wget https://nexus.phenotips.org/nexus/content/repositories/releases/org/phenotips/phenotips-standalone/1.2.6/phenotips-standalone-1.2.6.zip

rm phenotips-standalone-1.2.6.zip

SCRIPT=createStartPhenoTips.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/createStartPhenoTips.sh -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

#note: the below error is benign and phenotips should work regardless
## java.io.FileNotFoundException: 
##/data/new_seqr/phenotips-standalone-1.2.6/jetty/work/jetty-0.0.0.0-8080-phenotips-_-any-/xwiki-temp/ontologizer/.cache/.index (No such file or directory)

#Install other essential parts of seqr

cd ${SEQR_DIR} && SCRIPT=createStartElastSearch.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/createStartElastSearch.sh -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

cd ${SEQR_DIR} && SCRIPT=install_local.step1.install_pipeline_runner.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

cd ${SEQR_DIR} && SCRIPT=install_local.step4.kibana.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

cd ${SEQR_DIR} && SCRIPT=install_local.step5.install_redis.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

echo "Check that seqr is working by going to http://"$IP_ADDRESS":8000"
echo "PhenoTips should be available at http://"$IP_ADDRESS":8080"
