# POKT Node Setup Script
WARNING: The script in this repository has been very lightly tested, and may not appropriate for production node setup. Its intention is to speed up the process to create a node, not to replace the need for user interaction with their nodes entirely. 

I found that the existing [OPERATE A NODE](https://docs.pokt.network/access-tutorials) documentation had a few gaps. I documented the steps I had to follow instead below, and created a startup script that includes all of the steps to run on a node. 

## Preparation
Prior to running the script, you should follow the steps in the [Part 1 Server Setup](https://docs.pokt.network/access-tutorials/manual-setup-tutorial/part-1-server-setup) documentation. The server you create with these steps is where you will run the script. 

When I tried to sign up for Linode, I was immediately told I had to give more info about myself before I could use the node type recommended in the Pocket docs. As a result, I went to AWS and chose to spin up an `m6a.2xlarge` instance there instead. I used 150GB EBS root volume and did not attach any separate volumes. If you need to run a full node, the disk size will likely need to be larger. 

## Running the Script
Copy the script to your Ubuntu instance. The script takes a single argument: the name of the DNS zone you plan to deploy a new record into. Usage can be seen with an example domain below:
`sudo ./node-setup.sh example.com`

This will automatically create the cert for `pokt.example.com`, but you've already created your DNS records prior to running the script. If you do not create the DNS record first, CertBot will fail to generate you a certificate, and the Nginx service will not come up correctly. 

When you start the script, you will be asked to enter a password that will be used for the Pocket account that will be created. Make sure this is a strong password and that you can store the password in a secure location, as it is the password that would allow someone to extract your private key from your node. 
