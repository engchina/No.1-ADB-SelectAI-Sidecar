#!/usr/bin/env bash
set -euo pipefail

#####################################
# Guard: must be sourced
# source setup_miniconda_ubuntu.sh
#####################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ERROR:"
  echo "  This script must be run with:"
  echo "    source setup_miniconda_ubuntu.sh"
  echo "  or:"
  echo "    . setup_miniconda_ubuntu.sh"
  exit 1
fi

echo "===== Step 1: Install system libraries ====="
sudo apt-get update -y
sudo apt-get install -y \
  libreoffice \
  fonts-noto-cjk \
  fonts-noto-cjk-extra \
  fonts-ipafont \
  fonts-takao \
  fonts-wqy-microhei \
  fonts-wqy-zenhei

echo "===== Step 2: Download Miniconda installer ====="
MINICONDA_BASE="/u01/aipoc"
MINICONDA_DIR="${MINICONDA_BASE}/miniconda"
INSTALLER="${MINICONDA_BASE}/miniconda.sh"

sudo mkdir -p "${MINICONDA_BASE}"
sudo chown "$(id -u):$(id -g)" "${MINICONDA_BASE}"

wget -q -O "${INSTALLER}" \
  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

echo "===== Step 3: Install Miniconda (non-interactive) ====="
bash "${INSTALLER}" -b -p "${MINICONDA_DIR}"

echo "===== Step 4: Initialize conda for future shells ====="
"${MINICONDA_DIR}/bin/conda" init bash

echo "===== Step 5: Activate conda in CURRENT shell ====="
eval "$("${MINICONDA_DIR}/bin/conda" shell.bash hook)"

echo "===== Step 6: Accept conda Terms of Service ====="
conda tos accept --override-channels \
  --channel https://repo.anaconda.com/pkgs/main

conda tos accept --override-channels \
  --channel https://repo.anaconda.com/pkgs/r

echo "===== Step 7: Cleanup ====="
rm -f "${INSTALLER}"

echo "===== DONE ====="
echo "✔ conda is active in the CURRENT shell"
echo "✔ conda will also be active in future shells"
