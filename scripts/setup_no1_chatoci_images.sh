#!/usr/bin/env bash
set -euo pipefail

#####################################
# chmod +x /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/setup_no1_chatoci_images.sh
# /bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/setup_no1_chatoci_images.sh
#####################################

echo "===== Load conda ====="
source /u01/aipoc/miniconda/etc/profile.d/conda.sh

BASE_DIR="/u01/aipoc"
PROJECT_NAME="No.1-ChatOCI-Images"
PROJECT_DIR="${BASE_DIR}/${PROJECT_NAME}"
ENV_NAME="no.1-chatoci-images"
PORT="5005"

echo "===== Clone ${PROJECT_NAME} ====="
cd "${BASE_DIR}"
if [ ! -d "${PROJECT_NAME}" ]; then
  git clone https://github.com/engchina/No.1-ChatOCI-Images.git
fi

cd "${PROJECT_DIR}"

echo "===== Create conda env ====="
if ! conda env list | grep -q "${ENV_NAME}"; then
  conda create -n "${ENV_NAME}" python=3.12 -y
fi

echo "===== Install Python dependencies ====="
conda activate "${ENV_NAME}"
pip install --upgrade pip
pip install -r requirements.txt

echo "===== Init .env ====="
if [ ! -f ".env" ]; then
  cp .env.example .env
fi

echo "===== Open firewall port ${PORT} ====="
sudo iptables -C INPUT -p tcp --dport "${PORT}" -j ACCEPT 2>/dev/null \
  || sudo iptables -I INPUT -s 0.0.0.0/0 -p tcp --dport "${PORT}" -j ACCEPT

sudo netfilter-persistent save

echo "===== Install cron @reboot (current user) ====="
(
  crontab -l 2>/dev/null | \
  grep -v "No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh" || true
  echo "@reboot /bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh"
) | crontab -

echo "===== DONE: Installation complete ====="
echo "Service will start automatically after reboot"
