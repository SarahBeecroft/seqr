This directory contains scripts for installing seqr components on an ubuntu  server

Sarah Beecroft 29/2/2020
These notes are based of those from Brian Uapinyoying 07/26/2018 and the official instructions for installing on a linux machine

# A note on ports
If you are using a Nimbus VM, you will need to login into the openstack web interface, go to security groups, and edit your custom security group. you need to open ports 8000, 8080, and 27017 by adding a custom rule for each. 

Specs: ingress, IPv4, TCP, 8000 or 8080 or 27017, 0.0.0.0/0 


# Getting started
Update and upgrade apt-get:

    sudo apt-get update

Install python 2.7: 
    
    sudo apt-get install python

Install python pip and upgrade it

    sudo -H apt-get install python-pip
    sudo -H pip2 install --upgrade pip

Make an install directory for seqr. This is based in the volume store of my VM
        
        cd /data
        mkdir seqr seqr/elasticsearch
        cd seqr


Create an bash variable or alias and add it to `~/.bash_rc` and run `source ~/.bashrc`

    export SEQR_DIR="/data/seqr"
    export SEQR_BIN_DIR=${SEQR_DIR}/../bin
    sudo nano ~/.bashrc #add the above lines
    source ~/.bashrc

# Make background changes and download seqr repo

    SCRIPT=seqr_dependencies.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

# Install seqr's python dependencies

    cd ${SEQR_DIR}
    sudo apt-get install python-psycopg2
    sudo apt-get install libpq-dev
    sudo apt remove python-psycopg2
    sudo -H pip install -r seqr/requirements.txt

# Install tabix 
not strictly needed, but useful to have. Optional.

    sudo apt-get install tabix

# Install MongoDB

    sudo apt-get install mongodb
    mongo # to test if it works, Ctr+D to quit

# Install Postgres 
Instructions on how to install postgres on Ubuntu 16.04

    sudo apt-get install postgresql postgresql-contrib

Don't change the password to the postgres user, causes problems

Edit /etc/postgresql/<version>/main/pg_hba.conf to change permission settings to make postgres work (needs sudo)

    # Database administrative login by Unix domain socket
    local   all             postgres                                trust
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    # "local" is for Unix domain socket connections only
    local   all             all                                     trust
    # IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    #local   replication     postgres                                peer
    #host    replication     postgres        127.0.0.1/32            md5
    #host    replication     postgres        ::1/128                 md5

Restart the service, create a seqr database and test out a connection to the postgresql database

    sudo service postgresql restart
    psql -U postgres # Check connection with db, quit with ctr+D

db will be created in later step via install_local.step6.install_seqr.sh

# Install Oracle Java Development kit 8 (JDK v1.8)

Install the official Oracle Java Development kit 8 (JDK v1.8) for PhenoTips to work properly. Don't get the java runtime enviornment (JRE), it's not enough.

    sudo apt-get update
    sudo apt install openjdk-8-jre

# Install PhenoTips 
PhenoTips stores structured phenotype information. I installed it to the seqr home directory

    cd ${SEQR_DIR}
    sudo apt-get install unzip

    wget https://nexus.phenotips.org/nexus/content/repositories/releases/org/phenotips/phenotips-standalone/1.2.6/phenotips-standalone-1.2.6.zip

    rm phenotips-standalone-1.2.6.zip

    SCRIPT=createStartPhenoTips.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/createStartPhenoTips.sh -o $SCRIPT && chmod 777 $SCRIPT $$ ./$SCRIPT

note: the below error is benign and phenotips should work regardless

    java.io.FileNotFoundException: /data/new_seqr/phenotips-standalone-1.2.6/jetty/work/jetty-0.0.0.0-8080-phenotips-_-any-/xwiki-temp/ontologizer/.cache/.index (No such file or directory)

#do these steps to install other essential parts of seqr

    cd ${SEQR_DIR} && SCRIPT=createStartElastSearch.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/createStartElastSearch.sh -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

    cd ${SEQR_DIR} && SCRIPT=install_local.step1.install_pipeline_runner.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

    cd ${SEQR_DIR} && SCRIPT=install_local.step4.kibana.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

    cd ${SEQR_DIR} && SCRIPT=install_local.step5.install_redis.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT

    sudo apt autoremove

# Create a new django admin user

    ./${SEQR_DIR}/seqr/manage.py createsuperuser

# Open seqr
Seqr is running on http://<yourIP>:8080

Go to your web browser go to this address. Login with the user ID you just created

# Open phenotips

Phenotips is running on http://<yourIP>:8000
