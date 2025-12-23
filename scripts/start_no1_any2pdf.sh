#!/bin/bash

#####################################
# chmod +x /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_any2pdf.sh
# /bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_any2pdf.sh
#####################################

source /u01/aipoc/miniconda/etc/profile.d/conda.sh
conda activate no.1-any2pdf

cd /u01/aipoc/No.1-Any2Pdf

nohup python run_api_server.py \
  --host 0.0.0.0 \
  --port 5000 \
  > /u01/aipoc/No.1-Any2Pdf/any2pdf.log 2>&1 &

exit 0
