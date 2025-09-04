#!/bin/bash
echo "Initializing application setup..."

# Move to source directory
cd /u01/aidify/No.1-ADB-SelectAI-Sidecar

# Download and configure instantclient
echo "Setting up Oracle Instant Client..."
mkdir -p /u01/aipoc
wget https://download.oracle.com/otn_software/linux/instantclient/2380000/instantclient-basic-linux.x64-23.8.0.25.04.zip -O /u01/aipoc/instantclient-basic-linux.x64-23.8.0.25.04.zip
unzip /u01/aipoc/instantclient-basic-linux.x64-23.8.0.25.04.zip -d /u01/aipoc/
wget http://ftp.de.debian.org/debian/pool/main/liba/libaio/libaio1_0.3.113-4_amd64.deb -O /u01/aipoc/libaio1_0.3.113-4_amd64.deb
dpkg -i /u01/aipoc/libaio1_0.3.113-4_amd64.deb
sh -c "echo /u01/aipoc/instantclient_23_8 > /etc/ld.so.conf.d/oracle-instantclient.conf"
ldconfig
echo 'export LD_LIBRARY_PATH=/u01/aipoc/instantclient_23_8:$LD_LIBRARY_PATH' >> /etc/profile
echo 'export PATH=/u01/aipoc/instantclient_23_8:$PATH' >> /etc/profile
source /etc/profile
export LD_LIBRARY_PATH=/u01/aipoc/instantclient_23_8:$LD_LIBRARY_PATH
export PATH=/u01/aipoc/instantclient_23_8:$PATH

# Setting up ADB wallet and executing SQL
echo "Setting up ADB wallet and executing SQL..."
cd /u01/aidify/props
unzip -o wallet.zip -d wallet
sed -i 's|DIRECTORY="?\+/network/admin" *|DIRECTORY="/u01/aidify/props/wallet"|g' wallet/sqlnet.ora
export TNS_ADMIN=/u01/aidify/props/wallet
echo "TNS_ADMIN=$TNS_ADMIN"
ls -la $TNS_ADMIN
cat $TNS_ADMIN/sqlnet.ora
cat $TNS_ADMIN/tnsnames.ora
echo -e "BEGIN\nCTX_DDL.CREATE_PREFERENCE('world_lexer','WORLD_LEXER');\nEND;\n/\nexit;" | sqlplus -S ADMIN/$(cat adb_password.txt)@$(cat adb_dsn.txt)
echo "ADB initialization completed"

# Return to source directory
cd /u01/aidify/No.1-ADB-SelectAI-Sidecar

# Docker setup
chmod +x ./install_docker.sh
bash ./install_docker.sh
systemctl start docker

# Clone and install Dify
DIFY_BRANCH=$(cat /u01/aidify/props/dify_branch.txt)
git clone -b ${DIFY_BRANCH} https://github.com/langgenius/dify.git
cd dify/docker

# Get OCI configuration from Terraform outputs
ORACLE_PASSWORD=$(cat /u01/aidify/props/adb_password.txt)
ORACLE_DSN=$(cat /u01/aidify/props/adb_dsn.txt)
ORACLE_WALLET_PASSWORD=$(cat /u01/aidify/props/wallet_password.txt)
BUCKET_NAMESPACE=$(cat /u01/aidify/props/bucket_namespace.txt)
BUCKET_NAME=$(cat /u01/aidify/props/bucket_name.txt)
BUCKET_REGION=$(cat /u01/aidify/props/bucket_region.txt)
OCI_ACCESS_KEY=$(cat /u01/aidify/props/oci_access_key.txt)
OCI_SECRET_KEY=$(cat /u01/aidify/props/oci_secret_key.txt)

cp .env.example .env
sed -i "s|EXPOSE_NGINX_PORT=80|EXPOSE_NGINX_PORT=8080|g" .env

# Configure Oracle ADB as Vector Store
sed -i "s|VECTOR_STORE=.*|VECTOR_STORE=oracle|g" .env
sed -i "s|ORACLE_USER=.*|ORACLE_USER=admin|g" .env
sed -i "s|ORACLE_PASSWORD=.*|ORACLE_PASSWORD=${ORACLE_PASSWORD}|g" .env
sed -i "s|ORACLE_DSN=.*|ORACLE_DSN=${ORACLE_DSN}|g" .env
sed -i "s|ORACLE_WALLET_PASSWORD=.*|ORACLE_WALLET_PASSWORD=${ORACLE_WALLET_PASSWORD}|g" .env
sed -i "s|ORACLE_IS_AUTONOMOUS=.*|ORACLE_IS_AUTONOMOUS=true|g" .env

# Modify docker-compose.yaml to skip Oracle container
sed -i "s|      - oracle|      - oracle-skip|g" docker-compose.yaml

# Configure OCI Object Storage
sed -i "s|STORAGE_TYPE=opendal|STORAGE_TYPE=oci-storage|g" .env

# Configure OCI Object Storage environment variables
OCI_ENDPOINT=https://${BUCKET_NAMESPACE}.compat.objectstorage.${BUCKET_REGION}.oraclecloud.com
OCI_BUCKET_NAME=${BUCKET_NAME}
OCI_REGION=${BUCKET_REGION}

# Apply OCI configuration to .env file
sed -i "s|OCI_ENDPOINT=.*|OCI_ENDPOINT=${OCI_ENDPOINT}|g" .env
sed -i "s|OCI_BUCKET_NAME=.*|OCI_BUCKET_NAME=${OCI_BUCKET_NAME}|g" .env
sed -i "s|OCI_ACCESS_KEY=.*|OCI_ACCESS_KEY=${OCI_ACCESS_KEY}|g" .env
sed -i "s|OCI_SECRET_KEY=.*|OCI_SECRET_KEY=${OCI_SECRET_KEY}|g" .env
sed -i "s|OCI_REGION=.*|OCI_REGION=${OCI_REGION}|g" .env

# Update .env file with FILES_URL
EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
sed -i "s|^CONSOLE_API_URL=.*|CONSOLE_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^CONSOLE_WEB_URL=.*|CONSOLE_WEB_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^SERVICE_API_URL=.*|SERVICE_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^APP_API_URL=.*|APP_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^APP_WEB_URL=.*|APP_WEB_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^FILES_URL=.*|FILES_URL=http://${EXTERNAL_IP}:5001|" .env

# Create docker-compose.override.yaml with port configuration
cat > docker-compose.override.yaml << 'EOL'
services:
  api:
    ports:
      - '${DIFY_PORT:-5001}:${DIFY_PORT:-5001}'
EOL

docker compose up -d

# Unzip wallet and copy essential file to instantclient
unzip /u01/aidify/props/wallet.zip -d /u01/aidify/props/wallet
sed -i 's|DIRECTORY="?\+/network/admin" *|DIRECTORY="/u01/aidify/props/wallet"|g' /u01/aidify/props/wallet/sqlnet.ora
# Copy wallet to Dify container
docker cp /u01/aidify/props/wallet docker-worker-1:/app/api/storage/wallet

# Fix nltk download issues
docker exec docker-api-1 python -c "import nltk; nltk.download('punkt'); nltk.download('punkt_tab')"
docker exec docker-worker-1 python -c "import nltk; nltk.download('punkt'); nltk.download('punkt_tab')"

docker restart docker-worker-1 docker-api-1

# Initialization complete
echo "Initialization complete."
echo "Dify is ready to use at http://${EXTERNAL_IP}:8080"
