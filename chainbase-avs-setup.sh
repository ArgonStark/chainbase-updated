#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display logo
echo -e "${BLUE}"
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

# Print startup message
echo -e "${GREEN}Running chainbase AVS Operator...${NC}"

# Install Dependencies
echo -e "${YELLOW}Installing Dependencies...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
docker version

# Install Docker-Compose
echo -e "${YELLOW}Installing Docker-Compose...${NC}"
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Docker Permission to user
sudo groupadd docker
sudo usermod -aG docker $USER

# Install Go
echo -e "${YELLOW}Installing Go...${NC}"
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
go version

#!/bin/bash

# Check if 'eigenlayer' exists and delete it
if [ -e "eigenlayer" ]; then
    echo -e "${YELLOW}Found 'eigenlayer'. Deleting...${NC}"
    rm -rf eigenlayer
    echo -e "${GREEN}'eigenlayer' deleted successfully.${NC}"
else
    echo -e "${CYAN}'eigenlayer' not found. Skipping deletion.${NC}"
fi

# Check if '.eigenlayer' exists and delete it
if [ -d ".eigenlayer" ]; then
    echo -e "${YELLOW}Found '.eigenlayer'. Deleting...${NC}"
    rm -rf .eigenlayer
    echo -e "${GREEN}'.eigenlayer' deleted successfully.${NC}"
else
    echo -e "${CYAN}'.eigenlayer' not found. Skipping deletion.${NC}"
fi

# Check if eigenlayer exists
  echo -e "${YELLOW}Installing EigenLayer CLI...${NC}"
  curl -sSfL https://raw.githubusercontent.com/layr-labs/eigenlayer-cli/master/scripts/install.sh | sh -s
  export PATH=$PATH:~/bin
  eigenlayer --version


# Cloning Chainbase AVS repo
echo -e "${YELLOW}Cloning Chainbase AVS repository...${NC}"
git clone https://github.com/chainbase-labs/chainbase-avs-setup
cd chainbase-avs-setup/holesky

# Key Management
echo -e "${BLUE}Key Management: Choose how to proceed for each key type.${NC}"

# Manage ECDSA Key
echo -e "${YELLOW}Managing ECDSA Key...${NC}"
select option in "Import ECDSA Key" "Create ECDSA Key" "Already Imported"; do
  case $option in
    "Import ECDSA Key")
      read -p "Enter your ECDSA private key: " ECDSA_PRIVATEKEY
      eigenlayer operator keys import --key-type ecdsa opr "$ECDSA_PRIVATEKEY"
      break
      ;;
    "Create ECDSA Key")
      eigenlayer operator keys create --key-type ecdsa opr
      read -p "Have you backed up your ECDSA key? (yes/no): " ecdsa_backup
      if [ "$ecdsa_backup" != "yes" ]; then
        echo -e "${RED}Please back up your ECDSA key before proceeding.${NC}"
        exit 1
      fi
      break
      ;;
    "Already Imported")
      echo -e "${GREEN}Skipping ECDSA key creation/import...${NC}"
      break
      ;;
    *)
      echo -e "${RED}Invalid option. Please choose 1, 2, or 3.${NC}"
      ;;
  esac
done

# Manage BLS Key
echo -e "${YELLOW}Managing BLS Key...${NC}"
select option in "Import BLS Key" "Create BLS Key" "Already Imported"; do
  case $option in
    "Import BLS Key")
      read -p "Enter your BLS private key: " BLS_PRIVATEKEY
      eigenlayer operator keys import --key-type bls opr "$BLS_PRIVATEKEY"
      break
      ;;
    "Create BLS Key")
      eigenlayer operator keys create --key-type bls opr
      read -p "Have you backed up your BLS key? (yes/no): " bls_backup
      if [ "$bls_backup" != "yes" ]; then
        echo -e "${RED}Please back up your BLS key before proceeding.${NC}"
        exit 1
      fi
      break
      ;;
    "Already Imported")
      echo -e "${GREEN}Skipping BLS key creation/import...${NC}"
      break
      ;;
    *)
      echo -e "${RED}Invalid option. Please choose 1, 2, or 3.${NC}"
      ;;
  esac
done

# Funding EigenLayer Ethereum Address
echo -e "${BLUE}You need to fund your Eigenlayer address with at least 1 Holesky ETH. Did you fund your address (yes/no)?${NC}"
read -p "Choice: " fund_choice
if [ "$fund_choice" != "yes" ]; then
  echo -e "${YELLOW}Please fund your address before continuing.${NC}"
  exit 1
fi

# Configure & Register Operator
echo -e "${YELLOW}Configuring & registering operator...${NC}"
eigenlayer operator config create

# Upload metadata file to GitHub and edit operator.yaml
echo -e "${YELLOW}Upload the metadata file to your GitHub profile and provide the link:${NC}"
read -p "GitHub Metadata URL: " metadata_url
sed -i "s|metadata_url:.*|metadata_url: \"$metadata_url\"|" operator.yaml

# Running Eigenlayer Holesky Node
echo -e "${YELLOW}Running Eigenlayer Holesky Node...${NC}"
eigenlayer operator register operator.yaml
eigenlayer operator status operator.yaml

# Config Chainbase AVS and Edit .env File
echo -e "${GREEN}Configuring Chainbase AVS...${NC}"

# Prompt the user for manual inputs
echo -e "${YELLOW}Please enter the following information:${NC}"
read -p "Enter the full path to your ECDSA key file: " NODE_ECDSA_KEY_FILE_PATH
read -p "Enter the full path to your BLS key file: " NODE_BLS_KEY_FILE_PATH
read -sp "Enter the password for your ECDSA key: " OPERATOR_ECDSA_KEY_PASSWORD
echo ""
read -sp "Enter the password for your BLS key: " OPERATOR_BLS_KEY_PASSWORD
echo ""
read -p "Enter your operator address: " OPERATOR_ADDRESS

# Save values to the .env file
echo -e "${GREEN}Updating .env file with the provided information...${NC}"
cat <<EOL > .env
NODE_ECDSA_KEY_FILE_PATH=${NODE_ECDSA_KEY_FILE_PATH}
NODE_BLS_KEY_FILE_PATH=${NODE_BLS_KEY_FILE_PATH}
OPERATOR_ECDSA_KEY_PASSWORD=${OPERATOR_ECDSA_KEY_PASSWORD}
OPERATOR_BLS_KEY_PASSWORD=${OPERATOR_BLS_KEY_PASSWORD}
OPERATOR_ADDRESS=${OPERATOR_ADDRESS}

# Default settings
NODE_SOCKET=yourNodeSocket
OPERATOR_NAME=yourOperatorName

EOL

# Rest of the script continues...

# Create docker-compose.yml file
echo -e "${GREEN}Creating docker-compose.yml file for the updated setup...${NC}"
cat <<EOL > docker-compose.yml
services:
  jobmanager:
    image: repository.chainbase.com/network/ms_flink:v1.2-test
    container_name: chainbase_jobmanager
    hostname: chainbase_jobmanager
    command: "./bin/jobmanager.sh start-foreground"
    networks:
      - avs_network
    restart: unless-stopped

  taskmanager:
    image: repository.chainbase.com/network/ms_flink:v1.2-test
    container_name: chainbase_taskmanager
    hostname: chainbase_taskmanager
    depends_on:
      - jobmanager
    command: "./bin/taskmanager.sh start-foreground"
    networks:
      - avs_network
    restart: unless-stopped

  postgres:
    image: postgres:16.4
    container_name: chainbase_postgres
    hostname: chainbase_postgres
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
      - ./schema:/docker-entrypoint-initdb.d
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
      - POSTGRES_USER=${POSTGRES_USER:-postgres}
      - POSTGRES_DB=${POSTGRES_DB:-node}
    networks:
      - avs_network
    restart: unless-stopped

  node:
    image: repository.chainbase.com/network/chainbase-node:v0.2.1
    container_name: manuscript_node
    hostname: manuscript_node
    ports:
      - 8011:8011
    environment:
      - OPERATOR_ECDSA_KEY_PASSWORD=${OPERATOR_ECDSA_KEY_PASSWORD}
      - OPERATOR_BLS_KEY_PASSWORD=${OPERATOR_BLS_KEY_PASSWORD}
      - OPERATOR_ADDRESS=${OPERATOR_ADDRESS}
      - NODE_SOCKET=${NODE_SOCKET}
    volumes:
      - ./node.yaml:/app/node.yaml
      - ${NODE_ECDSA_KEY_FILE_PATH}:/app/node.ecdsa.key.json
      - ${NODE_BLS_KEY_FILE_PATH}:/app/node.bls.key.json
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - avs_network
    restart: unless-stopped
    depends_on:
      - postgres
      - jobmanager
      - taskmanager

  prometheus:
    image: prom/prometheus:v2.51.2
    user: ":"
    container_name: prometheus
    hostname: prometheus
    environment:
      - OPERATOR_NAME=${OPERATOR_NAME}
    volumes:
      - "./monitor-config/prometheus:/etc/prometheus"
    entrypoint: /etc/prometheus/run.sh
    networks:
      - avs_network
    restart: unless-stopped
    depends_on:
      - node
      - jobmanager
      - taskmanager

  grafana:
    image: grafana/grafana:11.1.7
    user: ":"
    container_name: grafana
    hostname: grafana
    volumes:
      - "./monitor-config/grafana:/etc/grafana"
      - "./monitor-config/dashboards:/var/lib/grafana/dashboards"
    ports:
      - 3010:3000
    networks:
      - avs_network
    restart: unless-stopped
    depends_on:
      - prometheus

networks:
  avs_network:
EOL

# Create folders for docker
echo -e "${GREEN}Creating necessary folders for Docker...${NC}"
source .env && mkdir -pv ${EIGENLAYER_HOME} ${CHAINBASE_AVS_HOME} ${NODE_LOG_PATH_HOST}

# Function to update docker compose command in script
fix_docker_compose() {
    FILE="chainbase-avs.sh"
    echo -e "${RED}Detected 'unknown shorthand flag: d in -d' error. Updating 'docker compose' to 'docker-compose' in $FILE...${NC}"
    
    # Replace 'docker compose' with 'docker-compose' using sed
    sed -i 's/docker compose/docker-compose/g' "$FILE"
    
    echo -e "${GREEN}Update completed. Retrying...${NC}"
}

# Starting docker to prevent problems 
echo -e "${GREEN}Starting Docker ...${NC}"
systemctl start docker

# Give permissions to bash script
echo -e "${GREEN}Giving execute permissions to chainbase-avs.sh...${NC}"
chmod +x ./chainbase-avs.sh

# Update docker compose command before running AVS
fix_docker_compose

# Run Chainbase AVS
echo -e "${GREEN}Registering AVS...${NC}"
./chainbase-avs.sh register

echo -e "${GREEN}Running AVS...${NC}"
./chainbase-avs.sh run

# AVS running successfully message
echo -e "${GREEN}AVS running successfully!${NC}"

# Get AVS link
echo -e "${GREEN}Fetching AVS link...${NC}"
export PATH=$PATH:~/bin
eigenlayer operator status operator.yaml

# Checking Operator Health
sleep 2
echo -e "${YELLOW}Checking operator health on port 8080...${NC}"
curl -i localhost:8080/eigen/node/health

# Checking the docker containers
echo -e "${YELLOW}Checking Docker containers...${NC}"
docker ps

echo -e "${GREEN}Setup complete!${NC}"
