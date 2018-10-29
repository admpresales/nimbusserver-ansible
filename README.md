# nimbusserver-ansible
Nimbus Server VMWare build files using Packer and Ansible

To work, install Packer as per the instructions (https://www.packer.io/intro/getting-started/install.html)
, and add packer to the system path.

To run the build, do:

packer build -var version=2018.09 nimbusserver.json

 

