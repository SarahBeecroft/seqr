#!/usr/bin/env bash

echo ==== Set environment variables =====

if [ -z "$(which python)" ]; then
    echo
    echo "'python' command not found. Please install python."
    echo
    exit 1
fi


if [ -z "$PLATFORM" ]; then

    export PLATFORM=$(python - <<EOF
import platform
p = platform.platform().lower()
if "centos" in p: print("centos")
elif "ubuntu" in p: print("ubuntu")
elif "darwin" in p: print("macos")
else: print("unknown")
EOF
)
    cat <(echo 'export PLATFORM='${PLATFORM}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc

fi


if [ -z "$SEQR_DIR"  ]; then

    export SEQR_DIR=/data/seqr
    export SEQR_BIN_DIR=${SEQR_DIR}/../bin
    cat <(echo 'export SEQR_DIR='${SEQR_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
    cat <(echo 'export SEQR_BIN_DIR='${SEQR_BIN_DIR}) ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
    cat <(echo 'export PATH='${SEQR_BIN_DIR}':$PATH') ~/.bashrc > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc

fi


set +x
echo ==== Install gcloud sdk =====
set -x

if [ -z "$PLATFORM" ]; then
    set +x
    echo "PLATFORM environment variable not set. Please run previous install step(s)."
    exit 1

elif [ $PLATFORM = "macos" ]; then

    # based on https://cloud.google.com/sdk/docs/quickstart-macos
    wget -N https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-221.0.0-darwin-x86_64.tar.gz
    tar xzf google-cloud-sdk-221.0.0-darwin-x86_64.tar.gz
    rm google-cloud-sdk-221.0.0-darwin-x86_64.tar.gz
    ./google-cloud-sdk/install.sh --quiet

    # make sure crcmod is installed for copying files with gsutil
    sudo easy_install -U pip
    sudo pip install -U crcmod

elif [ $PLATFORM = "centos" ]; then

    sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
    sudo yum install -y google-cloud-sdk

    # make sure crcmod is installed for copying files with gsutil
    sudo yum install -y gcc python-devel python-setuptools redhat-rpm-config
    sudo easy_install -U pip
    sudo pip uninstall crcmod
    sudo pip install -U crcmod

elif [ $PLATFORM = "ubuntu" ]; then

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
    sudo easy_install -U pip
    sudo pip uninstall crcmod
    sudo pip install -U crcmod

else
    set +x
    echo "Unexpected operating system: $PLATFORM"
    exit 1
fi;


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
GSUTIL_TEST="gsutil ls gs://hail-common/vep"
$GSUTIL_TEST
if [ $? -eq 0 ]; then
    echo gsutil works
else
    echo "$GSUTIL_TEST failed - unable to access public gs://hail-common bucket."
    echo "Try running 'gcloud init'. "
    exit 1
fi

echo "===== init utilities ====="
# install tabix, bgzip, samtools - which may be needed for VEP and the loading pipeline
mkdir -p $SEQR_BIN_DIR
gsutil -m cp gs://hail-common/vep/htslib/* ${SEQR_BIN_DIR}/ \
    && gsutil -m cp gs://hail-common/vep/samtools ${SEQR_BIN_DIR}/ \
    && chmod a+rx  ${SEQR_BIN_DIR}/tabix ${SEQR_BIN_DIR}/bgzip ${SEQR_BIN_DIR}/htsfile ${SEQR_BIN_DIR}/samtools


cd ${SEQR_INSTALL_DIR}/data/reference_data
mkdir loftee_data_grch37 loftee_data_grch38 homo_sapiens
gsutil -m cp -n -r gs://hail-common/vep/vep/GRCh37/loftee_data ${SEQR_INSTALL_DIR}/data/reference_data/loftee_data_grch37
gsutil -m cp -n -r gs://hail-common/vep/vep/GRCh38/loftee_data ${SEQR_INSTALL_DIR}/data/reference_data/oftee_data_grch38
gsutil -m cp -n -r gs://hail-common/vep/vep/homo_sapiens/85_GRCh37 ${SEQR_INSTALL_DIR}/data/reference_data/homo_sapiens
gsutil -m cp -n -r gs://hail-common/vep/vep/homo_sapiens/85_GRCh38 ${SEQR_INSTALL_DIR}/data/reference_data/homo_sapiens

#if [ ! -f /vep/variant_effect_predictor ]; then
#    gsutil -m cp -n -r gs://hail-common/vep/vep/ensembl-tools-release-85 /vep
#    gsutil -m cp -n -r gs://hail-common/vep/vep/Plugins /vep
#    ln -s /vep/ensembl-tools-release-85/scripts/variant_effect_predictor /vep/variant_effect_predictor
#fi

if [ ! -f /vep/1var.vcf ]; then
    git clone https://github.com/konradjk/loftee.git .
fi
