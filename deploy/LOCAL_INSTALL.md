The installation script works on Linux (Ubuntu). 

#### Prerequisites
 - *Hardware:*  At least **16 Gb RAM**, **2 CPUs**, **50 Gb disk space**  

 - *Software:*  
     - python2.7 (including pip2.7 not pip3)
     - on Linux only: root access with sudo
    
    his directory contains scripts for installing seqr components on an ubuntu  server

Sarah Beecroft 29/2/2020
These notes are based of those from Brian Uapinyoying 07/26/2018 and the official instructions for installing on a linux machine

#### A note on ports
If you are using a Nimbus VM, you will need to login into the openstack web interface, go to security groups, and edit your custom security group. you need to open ports 8000, 8080, and 27017 by adding a custom rule for each. 

Specs: ingress, IPv4, TCP, 8000 or 8080 or 27017, 0.0.0.0/0 

#### How to install
The run_install_local.sh script should provide full installation of a local seqr instance

```
cd <location for seqr dir to be created, i.e. /data volume store on nimbus>

SCRIPT=run_local_install.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && ./$SCRIPT
```

#### Open phenotips

Phenotips is running on <http://yourIP:8000>

#### Create a new django admin user (i.e. seqr admin user) --> follow the prompts

```
./${SEQR_DIR}/seqr/manage.py createsuperuser
```

#### Open seqr
Seqr is running on <http://yourIP:8080>

Find your IP address with

```
curl ifconfig.me
```

An example IP address is 253.119.93.924

Open <http://yourIP:8080> on your web browser. Login with the user ID you just created.

#### Creating a project 

A project in seqr represents a group of collaborators working together on one or more datasets. To create a project via the web browser:
 
1. On the dashboard page, click on "Create Project".  
2. Click on the new project.
3. Click on Edit Families & Individuals > Bulk Upload and upload a .fam file with individuals for the project.


#### TO DO: Instructions on annotating and loading datasets into seqr. look at https://github.com/SarahBeecroft/broad-software-notes/blob/master/seqr_installation_ubuntu16_vm.md

#### Adding data to your project
Now that the dataset is loaded into elasticsearch, it can be added to the project:

1. Go to the project page
2. Click on Edit Datasets
3. Enter the index name that the pipeline printed out when it completed, and submit the form.

After this you can click "Variant Search" for each family, or "Gene Search" to search across families.


Annotating and loading VCF callsets - option #2: annotate and load on-prem

Annotating a callset with VEP and reference data can be very slow - as slow as several variants / sec per CPU, so although it is possible to run the pipeline on a single machine, it is recommended to use multiple machines.

To annotate a callset on-prem, first download VEP and other reference data. If all your data is on GRCh38 (or GRCh37), then download the data only for that genome version.

The total download size is ~180Gb per genome version.

#Loading your data into seqr (Beta) from https://github.com/broadinstitute/seqr/blob/master/deploy/LOCAL_INSTALL.md#annotating-and-loading-vcf-callsets---option-2-annotate-and-load-on-prem

# authenticate to your gcloud account so you can download public reference data
gcloud auth application-default login  

# download VEP reference data
mkdir -p ${SEQR_DIR}/data/vep_data/homo_sapiens
cd ${SEQR_DIR}/data/vep_data
curl -L http://ftp.ensembl.org/pub/release-99/variation/indexed_vep_cache/homo_sapiens_vep_99_GRCh38.tar.gz | tar xzf - &

#  download loftee reference data
mkdir -p ${SEQR_DIR}/data/vep_data/loftee_data/GRCh37/
cd ${SEQR_DIR}/data/vep_data/loftee_data/GRCh37/
gsutil cat gs://seqr-reference-data/vep_data/loftee-beta/GRCh37.tar | tar xf  - & 

mkdir -p ${SEQR_DIR}/data/vep_data/loftee_data/GRCh38/
cd ${SEQR_DIR}/data/vep_data/loftee_data/GRCh38/
gsutil cat gs://seqr-reference-data/vep_data/loftee-beta/GRCh38.tar | tar xf  - & 

# download full reference data set for GRCh38
mkdir -p ${SEQR_DIR}/data/seqr-reference-data/GRCh38
cd ${SEQR_DIR}/data/seqr-reference-data/GRCh38
gsutil -m cp -r gs://seqr-reference-data/GRCh38/all_reference_data/combined_reference_data_grch38.ht .
gsutil -m cp -r gs://seqr-reference-data/GRCh38/clinvar/clinvar.GRCh38.2020-06-15.ht .

Then run the following commands to annotate your callset and load it into elasticsearch:

# authenticate to your gcloud account so you can download public reference data
gcloud auth application-default login  

# if your data is local, create a directory for your vcf files. docker-compose will mount this directory into the pipeline-runner container.
mkdir ./data/input_vcfs/ 
cp your-callset.vcf.gz ./data/input_vcfs/       # vcfs should be bgzip'ed
 
docker-compose up -d pipeline-runner            # start the pipeline-runner container 
docker-compose exec pipeline-runner /bin/bash   # open a shell inside the pipeline-runner container (analogous to ssh'ing into a remote machine)

# for GRCh38 callsets, run a command like the one below inside the pipeline-runner container to annotate and load your dataset into elasticsearch
python3 -m seqr_loading SeqrMTToESTask --local-scheduler \
    --reference-ht-path /seqr_reference_data/combined_reference_data_grch38.ht \
    --clinvar-ht-path /seqr-reference-data/GRCh38/clinvar/clinvar.GRCh38.2020-06-15.ht \
    --vep-config-json-path /vep85-GRCh38-loftee-gcloud.json \
    --es-host elasticsearch \
    --es-index-min-num-shards 3 \
    --sample-type WES \
    --es-index your-dataset-name \
    --genome-version 38 \
    --source-paths gs://your-bucket/GRCh38/your-callset.vcf.gz \   # this can also be a path inside /input_vcfs/
    --dest-path gs://your-bucket/GRCh38/your-callset.mt      # this can be a local path or gs:// path where you have write access

To run annotation and database loading as 2 separate steps, use the following commands instead of the SeqrMTToESTask command above:

    docker-compose exec pipeline-runner /bin/bash   # open a shell inside the pipeline-runner container (analogous to ssh'ing into a remote machine)

    SeqrVCFToMTTask --local-scheduler   
   # for GRCh38 callsets, run a command like the one below inside the pipeline-runner container to annotate and load your dataset into elasticsearch
   python3 -m seqr_loading SeqrVCFToMTTask --local-scheduler \
       --reference-ht-path /seqr_reference_data/combined_reference_data_grch38.ht \
       --clinvar-ht-path /seqr-reference-data/GRCh38/clinvar/clinvar.GRCh38.2020-06-15.ht \
       --vep-config-json-path /vep85-GRCh38-loftee-gcloud.json \
       --sample-type WES \
       --genome-version 38 \
       --source-paths gs://your-bucket/GRCh38/your-callset.vcf.gz \   # this can be a local path within the pipeline-runner container (eg. /input_vcfs/dir/your-callset.vcf.gz) or a gs:// path 
       --dest-path gs://your-bucket/GRCh38/your-callset.mt      # this can be a local path within the pipeline-runner container or a gs:// path where you have write access
 
    # load the annotated dataset into your local elasticsearch instance
   python3 -m seqr_loading SeqrMTToESTask --local-scheduler \
        --dest-path /input_vcfs/GRCh38/your-callset.mt \
        --genome-version 38 \
        --es-host elasticsearch  \
        --es-index your-callset-name

Adding a loaded dataset to a seqr project.

After the dataset is loaded into elasticsearch, it can be added to your seqr project with these steps:

    Go to the project page
    Click on Edit Datasets
    Enter the elasticsearch index name (set via the --es-index arg at loading time), and submit the form.

#### (optional): Enable read viewing in the browser

To make .bam/.cram files viewable in the browser through igv.js, see **[ReadViz Setup Instructions](deploy/READVIZ_SETUP.md)**       
