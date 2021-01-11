This directory contains scripts for installing seqr components on an ubuntu  server

Sarah Beecroft 29/2/2020
These notes are based of those from Brian Uapinyoying 07/26/2018 and the official instructions for installing on a linux machine https://github.com/leklab/broad-software-notes/blob/master/seqr_installation_ubuntu16_vm.md 

# A note on ports
If you are using a Nimbus VM, you will need to login into the openstack web interface, go to security groups, and edit your custom security group. you need to open ports 8000, 8080, and 27017 by adding a custom rule for each. 

Specs: ingress, IPv4, TCP, 8000 or 8080 or 27017, 0.0.0.0/0 

# To install

Follow instructions in https://github.com/SarahBeecroft/seqr/blob/master/deploy/LOCAL_INSTALL.md

# Create a new django admin user

    ./${SEQR_DIR}/seqr/manage.py createsuperuser

# Open seqr
Seqr is running on http://<yourIP>:8080

Go to your web browser go to this address. Login with the user ID you just created

# Open phenotips

Phenotips is running on http://<yourIP>:8000
