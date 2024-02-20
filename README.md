# POKT Node Setup Script
WARNING: The script in this repository has been very lightly tested, and is not yet appropriate for production node setup. Please make sure you understand what you are doing before starting to use this script. 

I found that the existing [OPERATE A NODE](https://docs.pokt.network/access-tutorials) documentation seemed outdated and had a few gaps. I documented the steps I had to follow instead below, and created a startup script that includes all of the steps to run on a node. 

## Node Setup
When I tried to sign up for Linode, I was immediately told I had to give more info about myself before I could use the node type recommended in the Pocket docs. As a result, I went back to AWS and chose to spin up an `m6a.2xlarge` instance there instead. 

## Running the Script
Write the script to your Ubuntu instance. The script takes a single argument: the name of the DNS zone you plan to deploy a new record into. Usage can be seen with an example domain below:
`sudo ./node-setup.sh example.com`