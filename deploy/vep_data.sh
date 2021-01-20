#!/bin/bash

#set seqr dir
SEQR_DIR=

#base copied from https://github.com/broadinstitute/seqr/blob/master/deploy/LOCAL_INSTALL.md

# authenticate to your gcloud account so you can download public reference data
gcloud auth application-default login  

# download VEP reference data
mkdir -p ${SEQR_DIR}/data/vep_data/homo_sapiens
cd ${SEQR_DIR}/data/vep_data
curl -L http://ftp.ensembl.org/pub/release-99/variation/indexed_vep_cache/homo_sapiens_vep_99_GRCh38.tar.gz | tar xzf - &

#  download loftee reference data
mkdir -p ${SEQR_DIR}/data/vep_data/loftee_data/GRCh38/
cd ${SEQR_DIR}/data/vep_data/loftee_data/GRCh38/
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/loftee.sql.gz
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.fai
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.gzi
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/gerp_conservation_scores.homo_sapiens.GRCh38.bw

# download full reference data set for GRCh38
mkdir -p ${SEQR_DIR}/data/seqr-reference-data/GRCh38
cd ${SEQR_DIR}/data/seqr-reference-data/GRCh38
gsutil -m cp -r gs://seqr-reference-data/GRCh38/all_reference_data/combined_reference_data_grch38.ht .
gsutil -m cp -r gs://seqr-reference-data/GRCh38/clinvar/clinvar.GRCh38.2020-06-15.ht .
