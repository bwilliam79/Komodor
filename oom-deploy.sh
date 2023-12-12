#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./oom-deploy.log

echo -e "Logging in to Argo CD\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_PASSWORD > $LOG_FILE 2>&1

echo -e "Deploying OOM simulator via Argo CD.\n"
kubectl create namespace oom-simulator >> $LOG_FILE 2>&1
argocd app create javaapp --repo https://github.com/bwilliam79/Komodor-App.git --dest-server https://kubernetes.default.svc --path oom --dest-namespace oom-simulator >> $LOG_FILE 2>&1
argocd app set javaapp --sync-option Replace=true >> $LOG_FILE 2>&1
argocd app sync javaapp >> $LOG_FILE 2>&1

echo -e "\n\nOOM Simulator deployed."