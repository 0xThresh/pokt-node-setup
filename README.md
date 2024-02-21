# POKT Node Setup Script
WARNING: The script in this repository has been very lightly tested, and may not appropriate for production node setup. Its intention is to speed up the process to create a node, not to replace the need for user interaction with their nodes entirely. 

I found that the existing [OPERATE A NODE](https://docs.pokt.network/access-tutorials) documentation had a few gaps. I documented the steps I had to follow instead below, and created a startup script that includes all of the steps to run on a node. 

## Node Setup
When I tried to sign up for Linode, I was immediately told I had to give more info about myself before I could use the node type recommended in the Pocket docs. As a result, I went to AWS and chose to spin up an `m6a.2xlarge` instance there instead. I used 150GB EBS root volume and did not attach any separate volumes. If you need to run a full node, the disk size will likely need to be larger. 

## Running the Script
Write the script to your Ubuntu instance. The script takes a single argument: the name of the DNS zone you plan to deploy a new record into. Usage can be seen with an example domain below:
`sudo ./node-setup.sh example.com`

This will automatically create the cert for `pokt.example.com`, but you will have to create your DNS records to match the domain. 

When you start the script, you will be asked to enter a password that will be used for the Pocket account that will be created. 