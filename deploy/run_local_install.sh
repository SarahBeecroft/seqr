#!/usr/bin/env bash

SEQR_INSTALL_BASE='/data'
SEQR_DIR='/data/seqr'
SEQR_BIN_DIR=${SEQR_DIR}'/../bin'
SPARK_VERSION="spark-2.0.2-bin-hadoop2.7"
KIBANA_VERSION=7.6.0
KIBANA_PLATFORM="linux"
IP_ADDRESS=$(curl ifconfig.me)
PLATFORM='ubuntu'

#==========================================================================================================#
echo "==== Clone the seqr repo ====="

cd ${SEQR_INSTALL_BASE}
mkdir -p $SEQR_BIN_DIR

export SEQR_BRANCH=master

git clone --recursive https://github.com/SarahBeecroft/seqr.git
cd seqr/
git checkout $SEQR_BRANCH

#==========================================================================================================#
#Create a bash variable, add it to ~/.bash_rc and run source ~/.bashrc

export SEQR_DIR=/data/seqr
export SEQR_BIN_DIR=${SEQR_DIR}'/../bin'
export SPARK_HOME=${SEQR_BIN_DIR}'/'${SPARK_VERSION}
cat <(echo 'export SEQR_DIR='${SEQR_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
cat <(echo 'export SEQR_BIN_DIR='${SEQR_BIN_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
cat <(echo 'export PATH='${SEQR_BIN_DIR}':$PATH') ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
cat <(echo 'export SPARK_HOME='${SPARK_HOME}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc

source ~/.bashrc

#==========================================================================================================#
echo "==== Install seqr dependencies ====="

cd ${SEQR_DIR}
sudo apt-get update
sudo apt-get install -y unzip wget bzip2     # general utilities
sudo apt-get install -y git gcc make patch   # general devel. deps.
sudo apt-get install -y openjdk-8-jdk        # needs this specific java version
sudo apt-get install -y python
sudo -H apt-get install -y python-pip
sudo -H pip2 install --upgrade pip
sudo -H pip install -r ${SEQR_DIR}/requirements.txt
sudo $(which pip) install --ignore-installed decorator==4.2.1
sudo $(which pip) install --upgrade pip jupyter
sudo apt-get install -y python-psycopg2
sudo apt-get install -y libpq-dev
sudo apt remove -y python-psycopg2
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install -y mongodb
sudo apt install -y cpanminus

#============================================================================================================#
echo "===== install perl 5.20 ====="

# this is used by the seqr pedigree image-generating script and by the variant effect predictor (VEP) which is run within hail 0.1
# the VEP hail 0.1 integration in particular depends on this specific version of VEP

wget http://www.cpan.org/authors/id/S/SH/SHAY/perl-5.20.3.tar.bz2
tar xjf perl-5.20.3.tar.bz2
rm perl-5.20.3.tar.bz2
cd perl-5.20.3
./configure.gnu
make
sudo make install

# install dependencies of the HaploPainter.pl script used to generate static pedigree images
sudo apt-get install -y \
    build-essential \
    libcairo2-dev \
    libglib2.0-bin \
    libglib2.0-0 \
    libgtk2.0-dev \
    libpango1.0-dev

#wget -nv https://raw.github.com/miyagawa/cpanminus/master/cpanm -O cpanm \
#    && chmod +x ./cpanm \
#    && 
sudo cpanm --notest \
    Cairo \
    DBI \
    Gtk2 \
    Tk \
    Sort::Naturally

curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && sudo apt-get install -y nodejs

#==========================================================================================================#
echo "===== Install spark ===="

cd ${SEQR_BIN_DIR} \
    && wget -nv https://archive.apache.org/dist/spark/spark-2.0.2/${SPARK_VERSION}.tgz \
    && tar xzf ${SPARK_VERSION}.tgz && rm ${SPARK_VERSION}.tgz

#==========================================================================================================#
echo" ==== Install gcloud sdk ====="

# copied from https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu

# Create environment variable for correct distribution
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
# Add the Cloud SDK distribution URI as a package source
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
# Import the Google Cloud Platform public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# Update the package list and install the Cloud SDK
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

# make sure crcmod is installed for copying files with gsutil
sudo apt-get install -y gcc python-dev python-setuptools
#sudo easy_install -U pip
sudo pip uninstall -y crcmod
sudo pip install -U crcmod

#==========================================================================================================#
echo "===== init gsutil ====="

# Add a generic key for accessing public google cloud storage buckets
# Using a top-level /.config directory so that config files (like core-site.xml) can be shared with the Docker container
sudo mkdir -p /.config/
sudo chmod 777 /.config/
cp ${SEQR_DIR}/deploy/secrets/shared/gcloud/* /.config/

if [ -e "/.config/service-account-key.json" ]; then
    # authenticate to google cloud using service account
    gcloud auth activate-service-account --key-file /.config/service-account-key.json
    cp /.config/boto ~/.boto
    sudo mv /etc/boto.cfg /etc/boto.cfg.aside  # /etc/boto.cfg leads to "ImportError: No module named google_compute_engine" on gcloud Ubuntu VMs, so move it out of the way
fi


# check that gsutil works and is able to access gs://hail-common/
GSUTIL_TEST="gsutil ls gs://hail-common/"
$GSUTIL_TEST
if [ $? -eq 0 ]; then
    echo gsutil works
else
    echo "$GSUTIL_TEST failed - unable to access public gs://hail-common bucket."
    echo "Try running 'gcloud init'. "
    exit 1
fi

#==========================================================================================================#
echo "===== init utilities ====="

# install tabix, bgzip, samtools - which may be needed for VEP and the loading pipeline
#mkdir -p $SEQR_BIN_DIR
gsutil -m cp gs://hail-common/vep/htslib/* ${SEQR_BIN_DIR}/ \
    && gsutil -m cp gs://hail-common/vep/samtools ${SEQR_BIN_DIR}/ \
    && chmod a+rx  ${SEQR_BIN_DIR}/tabix ${SEQR_BIN_DIR}/bgzip \
    ${SEQR_BIN_DIR}/htsfile ${SEQR_BIN_DIR}/samtools

#==========================================================================================================#
#Update Postgres pg_hba.conf to change permission settings to make postgres work

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

#===========================================================================================================#
echo
echo "==== Install data loading pipeline ===="
echo
##still buggy
##./local_install.sh: line 209: cpanm: command not found
##cp: cannot create regular file '/data/seqr/spark-2.0.2-bin-hadoop2.7/jars/': No such file or directory [thought this should be in seqr bin??]
# download and install VEP - steps based on gs://hail-common/vep/vep/GRCh37/vep85-GRCh37-init.sh and gs://hail-common/vep/vep/GRCh38/vep85-GRCh38-init.sh
wget -nv https://raw.github.com/miyagawa/cpanminus/master/cpanm -O cpanm && chmod +x cpanm
sudo chown -R $USER ~/.cpanm/  # make sure the user owns .cpanm
# VEP dependencies
cpanm --sudo --notest Set::IntervalTree
cpanm --sudo --notest PerlIO::gzip
cpanm --sudo --notest DBI
cpanm --sudo --notest CGI
cpanm --sudo --notest JSON
# LoFTEE dependencies
cpanm --sudo --notest DBD::SQLite
cpanm --sudo --notest List::MoreUtils

# install google storage connector which allows hail to access vds's in google buckets without downloading them first
cp ${SEQR_DIR}/hail_elasticsearch_pipelines/hail_builds/v01/gcs-connector-1.6.10-hadoop2.jar ${SPARK_HOME}/jars/
cp ${SEQR_DIR}/deploy/docker/pipeline-runner/config/core-site.xml ${SPARK_HOME}/conf/

mkdir -p ${SEQR_DIR}/vep/loftee_data_grch37 ${SEQR_DIR}/vep/loftee_data_grch38 ${SEQR_DIR}/vep/homo_sapiens
sudo ln -s ${SEQR_DIR}/vep /vep
sudo chmod -R 777 /vep

if [ ! -f /usr/local/bin/perl ]
then
    sudo ln -s /usr/bin/perl /usr/local/bin/perl
fi

# copy large data files
if [ -f /etc/boto.cfg ]
then
    sudo mv /etc/boto.cfg /etc/boto.cfg.aside  # /etc/boto.cfg leads to "ImportError: No module named google_compute_engine" on gcloud Ubuntu VMs, so move it out of the way
fi


[ ! -d /vep/loftee_data_grch37/loftee_data ] && gsutil -m cp -n -r gs://hail-common/vep/vep/GRCh37/loftee_data /vep/loftee_data_grch37
[ ! -d /vep/loftee_data_grch38/loftee_data ] && gsutil -m cp -n -r gs://hail-common/vep/vep/GRCh38/loftee_data /vep/loftee_data_grch38
[ ! -d /vep/homo_sapiens/85_GRCh37 ] && gsutil -m cp -n -r gs://hail-common/vep/vep/homo_sapiens/85_GRCh37 /vep/homo_sapiens
[ ! -d /vep/homo_sapiens/85_GRCh38 ] && gsutil -m cp -n -r gs://hail-common/vep/vep/homo_sapiens/85_GRCh38 /vep/homo_sapiens

if [ ! -f /vep/variant_effect_predictor ]; then
    gsutil -m cp -n -r gs://hail-common/vep/vep/ensembl-tools-release-85 /vep
    gsutil -m cp -n -r gs://hail-common/vep/vep/Plugins /vep
    ln -s /vep/ensembl-tools-release-85/scripts/variant_effect_predictor /vep/variant_effect_predictor
fi

if [ ! -f /vep/1var.vcf ]; then
    git clone https://github.com/konradjk/loftee.git /vep/loftee
    cp ${SEQR_DIR}/hail_elasticsearch_pipelines/gcloud_dataproc/vep_init/vep-gcloud-grch38.properties /vep/vep-gcloud-grch38.properties
    cp ${SEQR_DIR}/hail_elasticsearch_pipelines/gcloud_dataproc/vep_init/vep-gcloud-grch37.properties /vep/vep-gcloud-grch37.properties
    cp ${SEQR_DIR}/hail_elasticsearch_pipelines/gcloud_dataproc/vep_init/run_hail_vep85_GRCh37_vcf.sh /vep/run_hail_vep85_GRCh37_vcf.sh
    cp ${SEQR_DIR}/hail_elasticsearch_pipelines/gcloud_dataproc/vep_init/run_hail_vep85_GRCh38_vcf.sh /vep/run_hail_vep85_GRCh38_vcf.sh
    cp ${SEQR_DIR}/hail_elasticsearch_pipelines/gcloud_dataproc/vep_init/1var.vcf /vep/1var.vcf

    # (re)create the fasta index VEP uses
    rm /vep/homo_sapiens/85_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.index
    bash /vep/run_hail_vep85_GRCh37_vcf.sh /vep/1var.vcf

    # (re)create the fasta index VEP uses
    rm /vep/homo_sapiens/85_GRCh38/Homo_sapiens.GRCh38.dna.primary_assembly.fa.index
    bash /vep/run_hail_vep85_GRCh38_vcf.sh /vep/1var.vcf
fi

#==========================================================================================================#

echo ==== Adjust system settings for elasticsearch =====

# vm.max_map_count needs to be increased on linux for elasticsearch to run. It's not necessary on Mac.
MAX_MAP_COUNT=$(sysctl -b vm.max_map_count)
if [[ -n "$MAX_MAP_COUNT" ]] && (( $MAX_MAP_COUNT < 262144 )); then
    echo '
vm.max_map_count=262144
' | sudo tee -a /etc/sysctl.conf

    sudo sysctl -w vm.max_map_count=262144   # avoid elasticsearch error: "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]"

    needs_reboot=1
fi

if (( $(ulimit -n) < 65536)); then

    echo '
* hard	 nofile 65536
* soft	 nofile	65536
elasticsearch  nofile  65536
' | sudo tee -a /etc/security/limits.conf  # avoid elasticsearch error: "max file descriptors [4096] for elasticsearch process is too low, increase to at least [65536]"

    if [ $PLATFORM = "ubuntu" ]; then
        echo '
DefaultLimitNOFILE=65536
' | sudo tee -a /etc/systemd/user.conf

        echo '
DefaultLimitNOFILE=65536
' | sudo tee -a /etc/systemd/system.conf

        echo '
session required pam_limits.so
' | sudo tee -a /etc/pam.d/su
    fi

    needs_reboot=1
fi

# apply limit to current session
sudo prlimit --pid $$ --nofile=65536


#==========================================================================================================#
echo "==== Create start_elasticsearch.sh ====="

mkdir ${SEQR_DIR}/elasticsearch
cd ${SEQR_DIR}/elasticsearch

echo '
cd '$(pwd)'
LOG_FILE=$(pwd)/elasticsearch.log
(ES_JAVA_OPTS="-Xms3900m -Xmx3900m" nohup ./bin/elasticsearch -E network.host=0.0.0.0 >& ${LOG_FILE}) &
sleep 7;
curl http://localhost:9200
echo "Elasticsearch started in background. See ${LOG_FILE}"
' | tee start_elasticsearch.sh
chmod 777 ./start_elasticsearch.sh

./start_elasticsearch.sh

cd ${SEQR_DIR}

#==========================================================================================================#
echo
echo "==== Install and start kibana ====="
echo

cd ${SEQR_DIR}
wget -nv https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-${KIBANA_PLATFORM}-x86_64.tar.gz
tar xzf kibana-${KIBANA_VERSION}-${KIBANA_PLATFORM}-x86_64.tar.gz
rm kibana-${KIBANA_VERSION}-${KIBANA_PLATFORM}-x86_64.tar.gz
cd ${SEQR_DIR}/kibana-${KIBANA_VERSION}-${KIBANA_PLATFORM}-x86_64

echo '
cd '$(pwd)'
LOG_FILE=$(pwd)/kibana.log
(nohup ./bin/kibana >& ${LOG_FILE}) &
echo "Kibana started in background. See ${LOG_FILE}"
' | tee start_kibana.sh

chmod 777 ./start_kibana.sh

./start_kibana.sh

cd ${SEQR_DIR}

#==========================================================================================================#
echo
echo "==== Installing redis ===="
echo

cd ${SEQR_DIR}
wget -nv http://download.redis.io/redis-stable.tar.gz

tar xvzf redis-stable.tar.gz
rm redis-stable.tar.gz

mv redis-stable redis
cd redis

make
sudo make install

echo 'cd '$(pwd)'
LOG_FILE=$(pwd)/redis.log
(nohup redis-server ${SEQR_DIR}/deploy/docker/redis/redis.conf >& ${LOG_FILE}) &
echo "redis started in background on port 6379. See ${LOG_FILE}"
' | tee start_redis.sh

chmod 777 ./start_redis.sh

./start_redis.sh

cd ${SEQR_DIR}

#==========================================================================================================#
echo
echo "==== Installing PhenoTips ===="
echo

cd ${SEQR_DIR}
wget https://nexus.phenotips.org/nexus/content/repositories/releases/org/phenotips/phenotips-standalone/1.2.6/phenotips-standalone-1.2.6.zip
unzip phenotips-standalone-1.2.6.zip
rm phenotips-standalone-1.2.6.zip
cd ${SEQR_DIR}/phenotips-standalone-1.2.6

echo 'cd '$(pwd)'
LOG_FILE=$(pwd)/phenotips.log
(nohup ./start.sh >& ${LOG_FILE}) &
echo "PhenoTips started in background on port 8080. See ${LOG_FILE}"
' | tee start_phenotips.sh

chmod 777 start_phenotips.sh

./start_phenotips.sh

#note: the below error is benign and phenotips should work regardless
## java.io.FileNotFoundException: 
##/data/new_seqr/phenotips-standalone-1.2.6/jetty/work/jetty-0.0.0.0-8080-phenotips-_-any-/xwiki-temp/ontologizer/.cache/.index (No such file or directory)

#==========================================================================================================#
echo
echo "==== Installing seqr ===="
echo

cd ${SEQR_DIR}/
git pull
cp deploy/docker/seqr/config/gunicorn_config.py ${SEQR_DIR}

# init seqr db
psql -U postgres postgres -c "create database seqrdb"
psql -U postgres postgres -c "create database reference_data_db"

# init django
python -u manage.py makemigrations
python -u manage.py migrate
python -u manage.py check
python -u manage.py collectstatic --no-input
python -u manage.py loaddata variant_tag_types
python -u manage.py loaddata variant_searches

# download and restore gene reference data
REFERENCE_DATA_BACKUP_FILE=gene_reference_data_backup.gz
wget -N https://storage.googleapis.com/seqr-reference-data/gene_reference_data_backup.gz -O ${REFERENCE_DATA_BACKUP_FILE}

psql -U postgres reference_data_db <  <(gunzip -c ${REFERENCE_DATA_BACKUP_FILE})
rm ${REFERENCE_DATA_BACKUP_FILE}

# start gunicorn server
GUNICORN_WORKER_THREADS=4

echo 'cd '${SEQR_DIR}'
LOG_FILE=$(pwd)/gunicorn.log
nohup gunicorn -w '${GUNICORN_WORKER_THREADS}' -c gunicorn_config.py wsgi:application --bind 0.0.0.0:8000 >& ${LOG_FILE} &
echo "gunicorn started in background. See ${LOG_FILE}"
' > start_server.sh

chmod 777 start_server.sh

./start_server.sh

#===========================================================================================================#
echo "Check that seqr is working by going to http://"$IP_ADDRESS":8000"
echo "PhenoTips should be available at http://"$IP_ADDRESS":8080"
