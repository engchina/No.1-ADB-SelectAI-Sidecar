#!/usr/bin/env bash
set -euo pipefail

#####################################
# chmod +x /u01/aipoc/setup_no1_any2pdf.sh
# /bin/bash /u01/aipoc/setup_no1_any2pdf.sh
#####################################

echo "===== Load conda ====="
source /u01/aipoc/miniconda/etc/profile.d/conda.sh

echo "===== Clone No.1-Any2Pdf ====="
cd /u01/aipoc
if [ ! -d "No.1-Any2Pdf" ]; then
  git clone https://github.com/engchina/No.1-Any2Pdf
fi

cd No.1-Any2Pdf

echo "===== Create conda env ====="
if ! conda env list | grep -q "no.1-any2pdf"; then
  conda create -n no.1-any2pdf python=3.12 -y
fi

echo "===== Install Python dependencies ====="
conda activate no.1-any2pdf
pip install --upgrade pip
pip install -r requirements.txt

echo "===== Open firewall port 5000 ====="
sudo iptables -C INPUT -p tcp --dport 5000 -j ACCEPT 2>/dev/null \
  || sudo iptables -I INPUT -s 0.0.0.0/0 -p tcp --dport 5000 -j ACCEPT

sudo netfilter-persistent save

echo "===== Install cron @reboot (current user) ====="

(
  crontab -l 2>/dev/null | \
  grep -v "/u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_any2pdf.sh" || true
  echo "@reboot /bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_any2pdf.sh"
) | crontab -

echo "===== DONE: Installation complete ====="
echo "Service will start automatically after reboot"
