#!/bin/bash

# User setup
useradd -m -g sudo -s /bin/bash pocket

# Set required vars
POKT_VERSION="RC-0.11.1" 
DNS_HOSTNAME=$1

while true; do
  read -sp "Enter the password to be used for the Pocket account: " POCKET_ACCOUNT_PASSWORD
  echo

  read -sp "Confirm password: " confirm
  echo
  
  if [ "$password" = "$confirm" ]; then
    break
  else
    echo "Passwords do not match! Please try again."
  fi
done

# When using AWS, skip volume mount 
mkdir /mnt/data

# Move the home directory to the location of the data directory
usermod -d /mnt/data pocket 

# Update system packages
apt update
apt dist-upgrade -y

# Download required packages
apt-get install -y git build-essential curl file nginx certbot python3-certbot-nginx jq aria2

# Download Go
cd /mnt/data 
wget https://dl.google.com/go/go1.19.2.linux-amd64.tar.gz
tar -xf go1.19.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/mnt/data/go/bin' >> /mnt/data/.bashrc
echo 'export GOPATH=/mnt/data/go' >> /mnt/data/.bashrc
echo 'export GOBIN=/mnt/data/go/bin' >> /mnt/data/.bashrc
source /mnt/data/.bashrc
export HOME=/mnt/data

# Download Pocket 
mkdir -p /mnt/data/go/src/github.com/pokt-network
cd /mnt/data/go/src/github.com/pokt-network
git clone https://github.com/pokt-network/pocket-core.git
cd pocket-core
git checkout tags/$POKT_VERSION
go build -o /mnt/data/go/bin/pocket /mnt/data/go/src/github.com/pokt-network/pocket-core/app/cmd/pocket_core/main.go

# TODO: Only continue if var below isn't null to ensure setup worked correctly 
POCKET_CLI_VERSION=$(pocket version)
echo "$POCKET_CLI_VERSION"

# Begin Pocket configuration
cd /mnt/data
mkdir -p .pocket/data 
cd .pocket/data 

# Download snapshot file in the background
# TODO: Choose the file to download based on node type passed into script 
#wget -c "https://pocket-snapshot.liquify.com/files/pruned/(curl -s https://pocket-snapshot.liquify.com/files/pruned/latest.txt)" -O - | tar -xv -C /mnt/data/.pocket

# Create Pocket account and set as validator
echo "$POCKET_ACCOUNT_PASSWORD" | pocket accounts create
ACCOUNTS=$(pocket accounts list)
ADDRESS=$(echo "$ACCOUNTS" | grep -oE '\([0-9]+\)[[:space:]]+[a-fA-F0-9]+' | cut -d' ' -f2)
echo "$POCKET_ACCOUNT_PASSWORD" | pocket accounts set-validator $ADDRESS

# Insert seeds into config
export SEEDS=$(curl -s https://raw.githubusercontent.com/pokt-network/pocket-seeds/main/mainnet.txt \
| tr '\n' ',' \
| sed 's/,*$//')

pocket util print-configs \
| jq --arg seeds "$SEEDS" '.tendermint_config.P2P.Seeds = $seeds' \
| jq '.pocket_config.rpc_timeout = 15000' \
| jq '.pocket_config.rpc_port = "8082"' \
| jq '.pocket_config.remote_cli_url = "http://localhost:8082"' \
| jq . > /mnt/data/.pocket/config/config.json

# Create chains.json using default settings
# TODO: Use 'pocket util', not doing that for now since it requires user input 
cat <<EOF > /mnt/data/.pocket/config/chains.json
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
wget https://raw.githubusercontent.com/pokt-network/pocket-network-genesis/master/mainnet/genesis.json 

# Increase pocket user's ulimit 
echo "pocket soft nofile 16384" >> /etc/security/limits.conf

cat <<EOF > /etc/systemd/system/pocket.service
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
chown -R pocket:sudo /mnt/data

# Start the Pocket service
systemctl daemon-reload
systemctl enable pocket.service
systemctl start pocket.service

# Register the cert with your domain
certbot --nginx --domain pokt.$DNS_HOSTNAME --register-unsafely-without-email --no-redirect --agree-tos

# Create the required NGINX config 
cat <<EOF > /etc/nginx/sites-available/pocket 
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}

server {
    add_header Access-Control-Allow-Origin "*";
    listen 80 ;
    listen [::]:80 ;
    listen 8081 ssl;
    listen [::]:8081 ssl;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    server_name pokt.$DNS_HOSTNAME;

    location / {
        try_files $uri $uri/ =404;
    }

    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;

    ssl_certificate /etc/letsencrypt/live/pokt.$DNS_HOSTNAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pokt.$DNS_HOSTNAME/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location ~* ^/v1/client/(dispatch|relay|challenge|sim) {
        proxy_pass http://127.0.0.1:8082;
        add_header Access-Control-Allow-Methods "POST, OPTIONS";
        allow all;
    }

    location = /v1 {
        add_header Access-Control-Allow-Methods "GET";
        proxy_pass http://127.0.0.1:8082;
        allow all;
    }
}
EOF

systemctl stop nginx
chown -R www-data /etc/letsencrypt/live/pokt.$DNS_HOSTNAME
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/pocket /etc/nginx/sites-enabled/pocket
systemctl start nginx

# Enable ufw rules
ufw enable
ufw default deny
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 8081
ufw allow 26656
