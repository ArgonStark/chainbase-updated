#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display logo
echo -e "${GREEN}"
cat << "EOF"
                                               _____   _                    _    
     /\                                       / ____| | |                  | |   
    /  \     _ __    __ _    ___    _ __     | (___   | |_    __ _   _ __  | | __
   / /\ \   | '__|  / _ |  / _ \  | '_ \     \___ \  | __|  / _ | | '__| | |/ /
  / ____ \  | |    | (_| | | (_) | | | | |    ____) | | |_  | (_| | | |    |   < 
 /_/    \_\ |_|     \__, |  \___/  |_| |_|   |_____/   \__|  \__,_| |_|    |_|\_\
                     __/ |                                                       
                    |___/                                                        
EOF

sleep 3

echo -e "${NC}"

#!/bin/bash

# \033[1;36mUpdate and upgrade the system\033[0m
sudo apt update && sudo apt upgrade -y

# \033[1;36mAdd Docker's official GPG key and repository\033[0m
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# \033[1;36mInstall Docker\033[0m
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

docker version

# \033[1;36mInstall Docker Compose\033[0m
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# \033[1;36mInstall Go\033[0m
cd $HOME
ver="1.22.0"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# \033[1;36mInstall Eigenlayer CLI\033[0m
curl -sSfL https://raw.githubusercontent.com/layr-labs/eigenlayer-cli/master/scripts/install.sh | sh -s
export PATH=$PATH:~/bin
eigenlayer --version

# \033[1;36mClone Chainbase repository\033[0m
cd $HOME
git clone https://github.com/chainbase-labs/chainbase-avs-setup
cd chainbase-avs-setup/holesky

# \033[1;36mPrompt user for wallet setup\033[0m
echo "\033[1;33mDo you want to create or import Eigenlayer ECDSA and BLS keys?\033[0m"
echo "1. Create"
echo "2. Import"
read -rp "Choose an option (1/2): " wallet_option

if [ "$wallet_option" -eq 1 ]; then
    read -rp "Enter a name for your ECDSA key: " ecdsa_keyname
    eigenlayer operator keys create --key-type ecdsa "$ecdsa_keyname"

    read -rp "Enter a name for your BLS key: " bls_keyname
    eigenlayer operator keys create --key-type bls "$bls_keyname"
elif [ "$wallet_option" -eq 2 ]; then
    read -rp "Enter the name for your ECDSA key: " ecdsa_keyname
    read -rp "Enter your ECDSA private key: " ecdsa_privatekey
    eigenlayer operator keys import --key-type ecdsa "$ecdsa_keyname" "$ecdsa_privatekey"

    read -rp "Enter the name for your BLS key: " bls_keyname
    read -rp "Enter your BLS private key: " bls_privatekey
    eigenlayer operator keys import --key-type bls "$bls_keyname" "$bls_privatekey"
else
    echo "\033[1;31mInvalid option. Exiting.\033[0m"
    exit 1
fi

# \033[1;36mPrompt for funding the wallet\033[0m
echo "\033[1;33mEnsure your wallet is funded with 1 Holesky ETH before proceeding. Have you done this? (yes/no)\033[0m"
read -rp "Answer: " funded
if [ "$funded" != "yes" ]; then
    echo "\033[1;31mPlease fund your wallet and rerun the script.\033[0m"
    exit 1
fi

# \033[1;36mRegister the operator\033[0m
eigenlayer operator config create

echo "\033[1;33mHave you created a metadata file on GitHub? (yes/no)\033[0m"
read -rp "Answer: " metadata
if [ "$metadata" == "yes" ]; then
    echo "\033[1;33mEdit the operator.yaml file to include your metadata URL.\033[0m"
    nano /root/chainbase-avs-setup/holesky/operator.yaml
fi

eigenlayer operator register operator.yaml

# \033[1;36mPrompt user to fill in .env file information\033[0m
echo "\033[1;33mPlease provide the following information to configure the .env file.\033[0m"
read -rp "ECDSA key file path: " NODE_ECDSA_KEY_FILE_PATH
read -rp "BLS key file path: " NODE_BLS_KEY_FILE_PATH
read -rp "ECDSA key password: " OPERATOR_ECDSA_KEY_PASSWORD
read -rp "BLS key password: " OPERATOR_BLS_KEY_PASSWORD
read -rp "ECDSA key address: " OPERATOR_ADDRESS
read -rp "Server public IP: " NODE_SOCKET
NODE_SOCKET+":8011" = $NODE_SOCKET":8011"
read -rp "Operator name: " OPERATOR_NAME

cp .env.example .env
cat <<EOT > .env
NODE_ECDSA_KEY_FILE_PATH=$NODE_ECDSA_KEY_FILE_PATH
NODE_BLS_KEY_FILE_PATH=$NODE_BLS_KEY_FILE_PATH
OPERATOR_ECDSA_KEY_PASSWORD=$OPERATOR_ECDSA_KEY_PASSWORD
OPERATOR_BLS_KEY_PASSWORD=$OPERATOR_BLS_KEY_PASSWORD
OPERATOR_ADDRESS=$OPERATOR_ADDRESS
NODE_SOCKET=$NODE_SOCKET
OPERATOR_NAME=$OPERATOR_NAME
EOT

nano .env

# \033[1;36mStart the node\033[0m
chmod +x ./chainbase-avs.sh
./chainbase-avs.sh register
./chainbase-avs.sh run

