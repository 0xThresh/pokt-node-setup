# POKT Node Setup Script
> WARNING: The script in this repository has been very lightly tested, and is not yet appropriate for production node setup. Please make sure you understand what you are doing before starting to use this script. 

I found that the existing [OPERATE A NODE](https://docs.pokt.network/access-tutorials) documentation seemed outdated and had a few gaps. I documented the steps I had to follow instead below, and created a startup script that's working up until the [Create a Pocket wallet account](https://docs.pokt.network/access-tutorials/manual-setup-tutorial/part-3-pocket-configuration#create-a-pocket-wallet-account) section. 

## Node Setup
When I tried to sign up for Linode, I was immediately told I had to give more info about myself before I could use the node type recommended in the Pocket docs. As a result, I went back to AWS and chose to spin up an `m6a.large` instance there instead. 

The docs also reference that you need 800GB of storage; however, the current snapshot file is over 950GB, which means you're going to need at least 1TB of storage on your instance. 

## Snapshot files
The snapshot site referenced in the documentation no longer exists. I was able to find instructions on where to find a snapshot file here: https://github.com/pokt-network/pocket-core/blob/staging/doc/guides/snapshot.md

## Running the Script
I opted to run the `node-setup.sh` script as EC2 user data on AWS so that I didn't need to sign onto the host to get the process started. However, you can just as well copy the script into the EC2 instance via SSH if you'd prefer to watch the steps run through. Note that copying the snapshot files takes hours. 