#!/bin/bash

# Set strict mode
set -euo pipefail

# Set non-interactive mode to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Error handling function
handle_error() {
    log_error "Script failed at line $1 with exit code: $2"
    exit $2
}

# Set error trap
trap 'handle_error $LINENO $?' ERR

log "Starting application setup initialization..."

# Download function with retry mechanism
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Attempting to download $url (attempt $attempt)"
        if wget --timeout=30 --tries=3 "$url" -O "$output"; then
            log "Download successful: $output"
            return 0
        else
            log_error "Download failed (attempt $attempt): $url"
            if [ $attempt -eq $max_attempts ]; then
                log_error "Download failed after maximum retry attempts"
                return 1
            fi
            attempt=$((attempt + 1))
            sleep 5
        fi
    done
}

# Verify file existence
verify_file() {
    if [ ! -f "$1" ]; then
        log_error "File does not exist: $1"
        return 1
    fi
    log "File verification successful: $1"
}

# Move to source directory
log "Switching to source directory..."
cd /u01/aidify/No.1-ADB-SelectAI-Sidecar

# Download and configure Oracle Instant Client
log "Setting up Oracle Instant Client..."
mkdir -p /u01/aipoc

# Download instantclient-basic (fixed filename)
log "Downloading Oracle Instant Client Basic..."
download_with_retry "https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-basic-linux.x64-23.9.0.25.07.zip" "/u01/aipoc/instantclient-basic-linux.x64-23.9.0.25.07.zip"
verify_file "/u01/aipoc/instantclient-basic-linux.x64-23.9.0.25.07.zip"

log "Extracting Oracle Instant Client Basic..."
unzip -o -q /u01/aipoc/instantclient-basic-linux.x64-23.9.0.25.07.zip -d /u01/aipoc/

# Download and install libaio1
log "Downloading and installing libaio1..."
download_with_retry "http://ftp.de.debian.org/debian/pool/main/liba/libaio/libaio1_0.3.113-4_amd64.deb" "/u01/aipoc/libaio1_0.3.113-4_amd64.deb"
verify_file "/u01/aipoc/libaio1_0.3.113-4_amd64.deb"
dpkg -i --force-confold /u01/aipoc/libaio1_0.3.113-4_amd64.deb

# Configure library path
log "Configuring Oracle Instant Client library path..."
echo "/u01/aipoc/instantclient_23_9" > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Download instantclient-sqlplus
log "Downloading Oracle Instant Client SQL*Plus..."
download_with_retry "https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-sqlplus-linux.x64-23.9.0.25.07.zip" "/u01/aipoc/instantclient-sqlplus-linux.x64-23.9.0.25.07.zip"
verify_file "/u01/aipoc/instantclient-sqlplus-linux.x64-23.9.0.25.07.zip"

log "Extracting Oracle Instant Client SQL*Plus..."
unzip -o -q /u01/aipoc/instantclient-sqlplus-linux.x64-23.9.0.25.07.zip -d /u01/aipoc/

# Set environment variables (optimized to avoid duplication)
log "Configuring Oracle environment variables..."
export ORACLE_HOME=/u01/aipoc/instantclient_23_9
export LD_LIBRARY_PATH=/u01/aipoc/instantclient_23_9:${LD_LIBRARY_PATH:-}
export PATH=/u01/aipoc/instantclient_23_9:$PATH

# Write environment variables to profile (only once)
if ! grep -q "ORACLE_HOME=/u01/aipoc/instantclient_23_9" /etc/profile; then
    echo 'export ORACLE_HOME=/u01/aipoc/instantclient_23_9' >> /etc/profile
    echo 'export LD_LIBRARY_PATH=/u01/aipoc/instantclient_23_9:$LD_LIBRARY_PATH' >> /etc/profile
    echo 'export PATH=/u01/aipoc/instantclient_23_9:$PATH' >> /etc/profile
fi

log "Oracle Instant Client installation completed"
log "ORACLE_HOME=$ORACLE_HOME"
log "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
log "PATH=$PATH"

# Verify sqlplus installation
if command -v sqlplus >/dev/null 2>&1; then
    log "SQL*Plus installation verification successful"
else
    log_error "SQL*Plus installation verification failed"
    exit 1
fi

# Setup ADB wallet and execute SQL
log "Setting up ADB wallet and executing SQL..."
cd /u01/aidify/props

# Verify required files exist
verify_file "wallet.zip"
verify_file "adb_password.txt"
verify_file "adb_dsn.txt"

log "Extracting ADB wallet..."
unzip -o wallet.zip -d wallet

# Configure wallet path
log "Configuring wallet path..."
sed -i 's|DIRECTORY="?\+/network/admin" *|DIRECTORY="/u01/aidify/props/wallet"|g' wallet/sqlnet.ora
export TNS_ADMIN=/u01/aidify/props/wallet

log "TNS_ADMIN=$TNS_ADMIN"
log "Wallet file list:"
ls -la $TNS_ADMIN

log "sqlnet.ora contents:"
cat $TNS_ADMIN/sqlnet.ora

log "tnsnames.ora contents:"
cat $TNS_ADMIN/tnsnames.ora

# Execute SQL initialization
log "Executing ADB initialization SQL..."
ADB_PASSWORD=$(cat adb_password.txt)
ADB_DSN=$(cat adb_dsn.txt)

if echo -e "BEGIN\nCTX_DDL.CREATE_PREFERENCE('world_lexer','WORLD_LEXER');\nEND;\n/\nexit;" | sqlplus -S ADMIN/${ADB_PASSWORD}@${ADB_DSN}; then
    log "ADB initialization completed"
else
    log_error "ADB initialization failed"
    exit 1
fi

# Return to source directory
log "Returning to source directory..."
cd /u01/aidify/No.1-ADB-SelectAI-Sidecar

# Docker setup
log "Setting up Docker..."
verify_file "./install_docker.sh"
chmod +x ./install_docker.sh

log "Installing Docker..."
if bash ./install_docker.sh; then
    log "Docker installation successful"
else
    log_error "Docker installation failed"
    exit 1
fi

log "Starting Docker service..."
if systemctl start docker; then
    log "Docker service started successfully"
else
    log_error "Docker service startup failed"
    exit 1
fi

# Verify Docker status
if systemctl is-active --quiet docker; then
    log "Docker service is running normally"
else
    log_error "Docker service is not running properly"
    exit 1
fi

# Clone and install Dify
log "Cloning and installing Dify..."

# Verify required configuration files
verify_file "/u01/aidify/props/dify_branch.txt"
verify_file "/u01/aidify/props/adb_password.txt"
verify_file "/u01/aidify/props/adb_dsn.txt"
verify_file "/u01/aidify/props/wallet_password.txt"
verify_file "/u01/aidify/props/bucket_namespace.txt"
verify_file "/u01/aidify/props/bucket_name.txt"
verify_file "/u01/aidify/props/bucket_region.txt"
verify_file "/u01/aidify/props/oci_access_key.txt"
verify_file "/u01/aidify/props/oci_secret_key.txt"

# Read configuration
DIFY_BRANCH=$(cat /u01/aidify/props/dify_branch.txt)
log "Using Dify branch: $DIFY_BRANCH"

# Clone Dify repository
log "Cloning Dify repository..."
if git clone -b ${DIFY_BRANCH} https://github.com/langgenius/dify.git; then
    log "Dify repository cloned successfully"
else
    log_error "Dify repository clone failed"
    exit 1
fi

cd dify/docker

# Get OCI configuration
log "Reading OCI configuration..."
ORACLE_PASSWORD=$(cat /u01/aidify/props/adb_password.txt)
ORACLE_DSN=$(cat /u01/aidify/props/adb_dsn.txt)
ORACLE_WALLET_PASSWORD=$(cat /u01/aidify/props/wallet_password.txt)
BUCKET_NAMESPACE=$(cat /u01/aidify/props/bucket_namespace.txt)
BUCKET_NAME=$(cat /u01/aidify/props/bucket_name.txt)
BUCKET_REGION=$(cat /u01/aidify/props/bucket_region.txt)
OCI_ACCESS_KEY=$(cat /u01/aidify/props/oci_access_key.txt)
OCI_SECRET_KEY=$(cat /u01/aidify/props/oci_secret_key.txt)

log "OCI configuration reading completed"

# Configure Dify environment
log "Configuring Dify environment file..."
verify_file ".env.example"
cp -f .env.example .env

# Basic port configuration
log "Configuring basic port settings..."
sed -i "s|EXPOSE_NGINX_PORT=80|EXPOSE_NGINX_PORT=8080|g" .env

# Configure Oracle ADB as vector store
log "Configuring Oracle ADB as vector store..."
sed -i "s|VECTOR_STORE=.*|VECTOR_STORE=oracle|g" .env
sed -i "s|ORACLE_USER=.*|ORACLE_USER=admin|g" .env
sed -i "s|ORACLE_PASSWORD=.*|ORACLE_PASSWORD=${ORACLE_PASSWORD}|g" .env
sed -i "s|ORACLE_DSN=.*|ORACLE_DSN=${ORACLE_DSN}|g" .env
sed -i "s|ORACLE_WALLET_PASSWORD=.*|ORACLE_WALLET_PASSWORD=${ORACLE_WALLET_PASSWORD}|g" .env
sed -i "s|ORACLE_IS_AUTONOMOUS=.*|ORACLE_IS_AUTONOMOUS=true|g" .env

# Modify docker-compose.yaml to skip Oracle container
log "Modifying docker-compose.yaml configuration..."
verify_file "docker-compose.yaml"
sed -i "s|      - oracle|      - oracle-skip|g" docker-compose.yaml

# Configure OCI object storage
log "Configuring OCI object storage..."
sed -i "s|STORAGE_TYPE=opendal|STORAGE_TYPE=oci-storage|g" .env

# 配置 OCI 对象存储环境变量
log "设置 OCI 对象存储环境变量..."
OCI_ENDPOINT=https://${BUCKET_NAMESPACE}.compat.objectstorage.${BUCKET_REGION}.oraclecloud.com
OCI_BUCKET_NAME=${BUCKET_NAME}
OCI_REGION=${BUCKET_REGION}

log "OCI 端点: $OCI_ENDPOINT"
log "OCI 存储桶: $OCI_BUCKET_NAME"
log "OCI 区域: $OCI_REGION"

# 应用 OCI 配置到 .env 文件
log "应用 OCI 配置到环境文件..."
sed -i "s|OCI_ENDPOINT=.*|OCI_ENDPOINT=${OCI_ENDPOINT}|g" .env
sed -i "s|OCI_BUCKET_NAME=.*|OCI_BUCKET_NAME=${OCI_BUCKET_NAME}|g" .env
sed -i "s|OCI_ACCESS_KEY=.*|OCI_ACCESS_KEY=${OCI_ACCESS_KEY}|g" .env
sed -i "s|OCI_SECRET_KEY=.*|OCI_SECRET_KEY=${OCI_SECRET_KEY}|g" .env
sed -i "s|OCI_REGION=.*|OCI_REGION=${OCI_REGION}|g" .env

# Get external IP and update .env file
log "Getting external IP address..."
EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/ || echo "localhost")
if [ "$EXTERNAL_IP" = "localhost" ]; then
    log_error "Unable to get external IP, using localhost"
else
    log "External IP: $EXTERNAL_IP"
fi

# Update URL configuration in .env file
log "Updating URL configuration in environment file..."
sed -i "s|^CONSOLE_API_URL=.*|CONSOLE_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^CONSOLE_WEB_URL=.*|CONSOLE_WEB_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^SERVICE_API_URL=.*|SERVICE_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^APP_API_URL=.*|APP_API_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^APP_WEB_URL=.*|APP_WEB_URL=http://${EXTERNAL_IP}:8080|" .env
sed -i "s|^FILES_URL=.*|FILES_URL=http://${EXTERNAL_IP}:5001|" .env

# Create docker-compose.override.yaml port configuration
log "Creating Docker Compose override configuration..."
cat > docker-compose.override.yaml << 'EOL'
services:
  api:
    ports:
      - '${DIFY_PORT:-5001}:${DIFY_PORT:-5001}'
EOL

# Start Docker Compose
log "Starting Dify services..."
if docker compose up -d; then
    log "Dify services started successfully"
else
    log_error "Dify services startup failed"
    exit 1
fi

# Function to check container status with retry
check_container_status() {
    local container_name="$1"
    local max_attempts=10
    local wait_time=15
    
    for attempt in $(seq 1 $max_attempts); do
        log "Checking $container_name status (attempt $attempt/$max_attempts)..."
        
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
            log "$container_name is running normally"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log "$container_name not ready yet, waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi
    done
    
    log_error "$container_name failed to start properly after $max_attempts attempts"
    log "Container logs for $container_name:"
    docker logs --tail=20 "$container_name" 2>/dev/null || log "Could not retrieve logs for $container_name"
    return 1
}

# Wait for containers to start
log "Waiting for containers to start..."
sleep 45

# Verify container status with retry mechanism
log "Verifying container status with retry mechanism..."
check_container_status "docker-api-1" || exit 1
check_container_status "docker-worker-1" || exit 1

log "All containers are running successfully"

# Function to execute container operations with retry
execute_container_operation() {
    local container_name="$1"
    local operation_name="$2"
    local command="$3"
    local max_attempts=3
    local wait_time=10
    
    for attempt in $(seq 1 $max_attempts); do
        log "Executing $operation_name on $container_name (attempt $attempt/$max_attempts)..."
        
        if eval "$command"; then
            log "$operation_name on $container_name successful"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log "$operation_name failed, waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi
    done
    
    log_error "$operation_name on $container_name failed after $max_attempts attempts"
    return 1
}

# Configure wallet files to containers
log "Configuring wallet files to Dify containers..."
sed -i 's|DIRECTORY="?\+/network/admin" *|DIRECTORY="/u01/aidify/props/wallet"|g' /u01/aidify/props/wallet/sqlnet.ora

# Copy wallet to Dify containers with retry
log "Copying wallet to Dify containers..."
execute_container_operation "docker-worker-1" "wallet copy" "docker cp /u01/aidify/props/wallet docker-worker-1:/app/api/storage/wallet" || exit 1

# Fix NLTK download issues with retry
log "Fixing NLTK download issues..."
execute_container_operation "docker-api-1" "NLTK configuration" "docker exec docker-api-1 python -c 'import nltk; nltk.download(\"punkt\", quiet=True); nltk.download(\"punkt_tab\", quiet=True)'" || log "API container NLTK configuration failed, continuing..."

execute_container_operation "docker-worker-1" "NLTK configuration" "docker exec docker-worker-1 python -c 'import nltk; nltk.download(\"punkt\", quiet=True); nltk.download(\"punkt_tab\", quiet=True)'" || log "Worker container NLTK configuration failed, continuing..."

# Restart containers to apply configuration with retry
log "Restarting containers to apply configuration..."
execute_container_operation "docker-worker-1,docker-api-1" "container restart" "docker restart docker-worker-1 docker-api-1" || exit 1

# Wait and verify containers are running after restart
log "Waiting for containers to restart..."
sleep 30
check_container_status "docker-api-1" || exit 1
check_container_status "docker-worker-1" || exit 1

# Final service verification with retry
log "Performing final service verification..."
max_service_attempts=12
service_wait_time=30

for attempt in $(seq 1 $max_service_attempts); do
    log "Verifying service availability (attempt $attempt/$max_service_attempts)..."
    
    if curl -s -f "http://${EXTERNAL_IP}:8080" >/dev/null 2>&1; then
        log "Dify service verification successful"
        break
    fi
    
    if [ $attempt -lt $max_service_attempts ]; then
        log "Service not ready yet, waiting ${service_wait_time}s before retry..."
        sleep $service_wait_time
    else
        log "Service verification failed after $max_service_attempts attempts"
        log "Please check container logs and try accessing http://${EXTERNAL_IP}:8080 manually"
        log "Container status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
done

# Initialization completed
log "=== Initialization completed ==="
log "Dify is ready, access URL: http://${EXTERNAL_IP}:8080"
log "If the service is not immediately available, please wait a few more minutes for all services to fully start"
