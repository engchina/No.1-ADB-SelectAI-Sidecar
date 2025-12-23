#!/bin/bash

#####################################
# chmod +x /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh
# /bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh
#####################################

source /u01/aipoc/miniconda/etc/profile.d/conda.sh
conda activate no.1-chatoci-images

cd /u01/aipoc/No.1-ChatOCI-Images

nohup python app.py \
  > /u01/aipoc/No.1-ChatOCI-Images/chatoci-images.log 2>&1 &

exit 0
