#!/bin/bash
# 06/20/2024 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Log file for output
LOG_FILE=./komodor-deploy.log

echo -e "Enter k8s cluster name:"
read K8S_CLUSTER_NAME

echo -e "\nEnter Komodor API key:"
read API_KEY

echo -e "\nDeploying Komodor.\n"
helm repo add komodorio https://helm-charts.komodor.io >> $LOG_FILE 2>&1
helm repo update >> $LOG_FILE 2>&1
helm install komodor-agent komodorio/komodor-agent \
 --set apiKey=$API_KEY \
 --set clusterName=$K8S_CLUSTER_NAME \
 --timeout=90s \
 && start https://app.komodor.com/main/services >> $LOG_FILE 2>&1

sleep 5

COUNTER=0
echo -en "Waiting for Komodor deployment to complete."
until kubectl get pods -n default | grep komodor-agent | grep -i 'running' | grep 4/4 >> $LOG_FILE 2>&1
do
    ((COUNTER+=1))
    echo -n "."
    sleep 2
    if [ $COUNTER -eq 45 ]; then
        printf "\n\033[33;31mKmomodor deployment failed to complete\041\033[33;37m\n"
        exit 1
    fi
done

echo -e "\n\nKomodor deployment complete!"