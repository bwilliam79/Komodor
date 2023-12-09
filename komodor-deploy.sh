#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Log file for output
LOG_FILE=./komodor-deploy.log

echo -e "Enter Komodor API Key:"
read API_KEY

echo -e "\nDeploying Komodor.\n"
helm repo add komodorio https://helm-charts.komodor.io >> $LOG_FILE 2>&1
helm repo update >> $LOG_FILE 2>&1
helm upgrade --install k8s-watcher komodorio/k8s-watcher \
 --set apiKey=$API_KEY \
 --set watcher.clusterName=kind \
 --timeout=90s >> $LOG_FILE 2>&1

sleep 5

COUNTER=0
echo -en "Waiting for Komodor deployment to complete."
until kubectl get pods -n komodor | grep k8s-watcher | grep -i 'running' | grep 4/4 >> $LOG_FILE 2>&1
do
    ((COUNTER+=1))
    echo -n "."
    sleep 2
    if [ $COUTER -eq 45 ]; then
        echo -e "\nKmomodor deployment failed to complete!"
        exit 1
    fi
done

echo -e "\nKomodor deployment complete!"