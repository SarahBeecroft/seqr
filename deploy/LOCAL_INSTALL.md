The installation script works on Linux (Ubuntu). 

#### Prerequisites
 - *Hardware:*  At least **16 Gb RAM**, **2 CPUs**, **50 Gb disk space**  

 - *Software:*  
     - python2.7    
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

SCRIPT=run_local_install.sh && curl -L http://raw.githubusercontent.com/SarahBeecroft/seqr/master/deploy/$SCRIPT -o $SCRIPT && chmod 777 $SCRIPT && sudo ./$SCRIPT
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


#### (optional): Enable read viewing in the browser

To make .bam/.cram files viewable in the browser through igv.js, see **[ReadViz Setup Instructions](deploy/READVIZ_SETUP.md)**       
