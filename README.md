# hlfv11
Installation procedure for Hyperledger fabric 1.1.0 &amp; Composer 19.5.0 for IBM Cloud 

To create the fabric in the kube cluster, go to the cs-offerings/scripts folder, then run : create/create_all.sh --with-couchdb
All component, included the Composer Payground, will be installed.

Complete the installation installing the composer rest server with the following command : 
COMPOSER_CARD=<card name to admin the business network> create/create_composer-rest-server.sh

More info : https://ibm-blockchain.github.io/


