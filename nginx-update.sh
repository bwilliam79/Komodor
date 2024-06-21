#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./nginx-update.log

echo -e "Logging in to Argo CD\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_PASSWORD > $LOG_FILE 2>&1

echo -e "Syncing nginx deployment via Argo CD.\n"
argocd app sync nginx >> $LOG_FILE 2>&1

echo -en "Waiting for nginx deployment to stabilize."
until kubectl get pods -n web-services | grep nginx | grep -i 'running' | grep 1/1 >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done