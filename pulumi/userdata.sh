#!/bin/bash

# Variables:
# POKT_VERSION - the version of pocket-core to pull

# User setup
useradd -m -g sudo -s /bin/bash pocket

# Set required vars
POKT_VERSION="RC-0.11.1" 

# When using AWS, skip volume mount 
sudo mkdir /mnt/data

# Move the home directory to the location of the data directory
sudo usermod -d /mnt/data pocket 

# Update system packages
sudo apt update
sudo apt dist-upgrade -y

# Download required packages
sudo apt-get install -y git build-essential curl file nginx certbot python3-certbot-nginx jq aria2

# Download Go
cd /mnt/data 
wget https://dl.google.com/go/go1.19.2.linux-amd64.tar.gz
sudo tar -xvf go1.19.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:$HOME/go/bin' >> /mnt/data/.profile
echo 'export GOPATH=$HOME/go' >> /mnt/data/.profile
echo 'export GOBIN=$HOME/go/bin' >> /mnt/data/.profile
source /mnt/data/.profile 

# Download Pocket 
sudo mkdir -p $GOPATH/src/github.com/pokt-network
cd $GOPATH/src/github.com/pokt-network
sudo git clone https://github.com/pokt-network/pocket-core.git
cd pocket-core
sudo git checkout tags/$POKT_VERSION
go build -o $GOPATH/bin/pocket $GOPATH/src/github.com/pokt-network/pocket-core/app/cmd/pocket_core/main.go

# TODO: Only continue if var below isn't null to ensure setup worked correctly 
POCKET_CLI_VERSION=$(pocket version)
echo "$POCKET_CLI_VERSION"

# Begin Pocket configuration
cd /mnt/data
mkdir -p .pocket/data 
cd .pocket/data 

# Download snapshot file in the background
wget -O latest.txt https://pocket-snapshot.liquify.com/files/latest.txt
latestFile=$(cat latest.txt)
wget -c "https://pocket-snapshot.liquify.com/files/$latestFile" -O - | tar -xv -C /mnt/data/.pocket/data
rm latest.txt

# TODO: Enter account creation steps 

# Take a backup of the existing config file
cp /mnt/data/.pocket/config/config.json /mnt/data/.pocket/config/config.json.bak 

# Insert seeds into config
export SEEDS=$(curl -s https://raw.githubusercontent.com/pokt-network/pocket-seeds/main/mainnet.txt \
tr '\n' ',' \
sed 's/,*$//')

pocket util print-configs \
jq --arg seeds "$SEEDS" '.tendermint_config.P2P.Seeds = $seeds' \
jq '.pocket_config.rpc_timeout = 15000' \
jq '.pocket_config.rpc_port = "8082"' \
jq '.pocket_config.remote_cli_url = "http://localhost:8082"' \
jq . > ~/.pocket/config/config.json

# Create chains.json using default settings
# TODO: Use 'pocket util', not doing that for now since it requires user input 
cat << EOF > /mnt/data/.pocket/config/chains.json
[
  {
    "id": "0001",
    "url": "http://127.0.0.1:8082/",
    "basic_auth": {
      "username": "",
      "password": ""
    }
  }
]
EOF

# Create genesis.json
cd /mnt/data/.pocket/config
wget https://raw.githubusercontent.com/pokt-network/pocket-network-genesis/master/mainnet/genesis.json genesis.json

# Increase pocket user's ulimit 
echo "pocket soft nofile 16384" >> /etc/security/limits.conf

cat << EOF > /etc/systemd/system/pocket.service
[Unit]
Description=Pocket Service
After=network.target mnt-data.mount
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
User=pocket
Group=sudo
ExecStart=/mnt/data/go/bin/pocket start
ExecStop=/mnt/data/go/bin/pocket stop

[Install]
WantedBy=default.target
EOF

# Make sure all files are owned by the Pocket user before continuing 
sudo chown -R pocket /mnt/data

# Start the Pocket service
systemctl daemon-reload
systemctl enable pocket.service
systemctl start pocket.service

# Register the cert with your domain
sudo certbot --nginx --domain ${HOSTNAME} --register-unsafely-without-email --no-redirect --agree-tos