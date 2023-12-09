#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Log file for output
LOG_FILE=./komodor-deploy.log

echo -e "Enter Komodor API Key:"
read API_KEY

echo -e "Deploying Komodor.\n"
kubectl create namespace komodor > $LOG_FILE 2>&1
helm repo add komodorio https://helm-charts.komodor.io >> $LOG_FILE 2>&1
helm repo update >> $LOG_FILE 2>&1
helm upgrade --install k8s-watcher komodorio/k8s-watcher \
 --set apiKey=$API_KEY \
 --set watcher.clusterName=kind \
 --timeout=90s \
 --set watcher.enableAgentTaskExecution=true \
 --set watcher.allowReadingPodLogs=true >> $LOG_FILE 2>&1

echo -en "Waiting for Komodor deployment to complete."
until kubectl get pods -n komodor | grep k8s-watcher | grep -i 'running' | grep 4/4 >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done

echo -e "\nKomodor deployment complete!"