#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./nginx-destroy-nginx.log

echo -e "Logging in to Argo CD\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_PASSWORD > $LOG_FILE 2>&1

echo -e "Destroying nginx via Argo CD.\n"
argocd app delete nginx >> $LOG_FILE 2>&1

echo -e "Removing port forward for nginx service.\n"
kill -HUP `ps -ax | grep port-forward | grep web-services | awk '{$1=$1};1' | cut -f 1 -d ' '` >> $LOG_FILE 2>&1

kubectl delete namespace web-services >> $LOG_FILE 2>&1

echo -e "nginx deployment destroyed!"