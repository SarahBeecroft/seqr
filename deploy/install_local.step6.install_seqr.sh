#!/usr/bin/env bash

set +x
set +x

if [ -z "$SEQR_DIR"  ]; then
    echo "SEQR_DIR environment variable not set. Please run install_general_dependencies.sh as described in step 1 of https://github.com/macarthur-lab/seqr/blob/master/deploy/LOCAL_INSTALL.md"
    exit 1
fi

echo "===== install perl 5.20 ====="

# this is used by the seqr pedigree image-generating script and by the variant effect predictor (VEP) which is run within hail 0.1
# the VEP hail 0.1 integration in particular depends on this specific version of VEP

wget http://www.cpan.org/authors/id/S/SH/SHAY/perl-5.20.3.tar.bz2
tar xjf perl-5.20.3.tar.bz2
cd perl-5.20.3
./configure.gnu
make
sudo make install


echo
echo "==== Installing seqr ===="
echo
set -x

# install dependencies of the HaploPainter.pl script used to generate static pedigree images
sudo apt-get install -y \
build-essential \
libcairo2-dev \
libglib2.0-bin \
libglib2.0-0 \
libgtk2.0-dev \
libpango1.0-dev

sudo apt-get update \
  && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && sudo apt-get install -y \
    nodejs

wget -nv https://raw.github.com/miyagawa/cpanminus/master/cpanm -O cpanm \
    && chmod +x ./cpanm \
    && sudo ./cpanm --notest \
        Cairo \
        DBI \
        Gtk2 \
        Tk \
        Sort::Naturally

cd ${SEQR_DIR}/
git pull
cp deploy/docker/seqr/config/gunicorn_config.py ${SEQR_DIR}/

# install python dependencies
cd ${SEQR_DIR}/
sudo $(which pip) install --upgrade --ignore-installed -r requirements.txt

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

echo '
LOG_FILE=${SEQR_DIR}/gunicorn.log
nohup gunicorn -w '${GUNICORN_WORKER_THREADS}' -c gunicorn_config.py wsgi:application --bind 0.0.0.0:8000 >& ${LOG_FILE} &
echo "gunicorn started in background. See ${LOG_FILE}"
' > start_server.sh
chmod 777 ./start_server.sh

./start_server.sh

set +x
