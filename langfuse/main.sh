#!/bin/bash
nohup /usr/bin/docker compose -p langfuse -f /u01/aipoc/No.1-ADB-SelectAI-Sidecar/langfuse/docker-compose.yml up -d &
exit 0