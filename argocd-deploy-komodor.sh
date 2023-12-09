#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./argocd-deploy-komodor.log

# Generate random string for unique deployment naming
RANDOM_NAME=`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8`

echo -e "Deploying Argo CD.\n"
kubectl create namespace argocd > $LOG_FILE 2>&1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >> $LOG_FILE 2>&1

echo -en "Waiting for Argo CD deployment to complete."
until kubectl get pods -n argocd | grep argocd-server | grep -i 'running' | grep 1/1 >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done

echo -e "\n\nSetting up port forward for Argo CD API server."
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

# Insert sleep because it sometimes takes a bit for the port forward to be active
sleep 2

ARGOCD_INITIAL_PASSWORD=`argocd admin initial-password -n argocd | head -n 1`

echo -e "\nLogging in to Argo CD to change initial password.\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_INITIAL_PASSWORD >> $LOG_FILE 2>&1
argocd account update-password --current-password $ARGOCD_INITIAL_PASSWORD --new-password $ARGOCD_PASSWORD >> $LOG_FILE 2>&1

echo -e "Registering k8s cluster with Argo CD.\n"
argocd cluster add kind-kind -y >> $LOG_FILE 2>&1

echo -e "Deploying Komodor.\n"
helm repo add komodorio https://helm-charts.komodor.io >> $LOG_FILE 2>&1
helm repo update >> $LOG_FILE 2>&1
helm upgrade --install k8s-watcher komodorio/k8s-watcher \
 --set apiKey=5be49593-8121-4e7a-9f9c-6d7c4f7acf42 \
 --set watcher.clusterName=kind \
 --timeout=90s \
 --set watcher.enableAgentTaskExecution=true \
 --set watcher.allowReadingPodLogs=true >> $LOG_FILE 2>&1

echo -en "Waiting for things to settle."
 COUNTER=0
 while [ $COUNTER -lt 10 ]; do
    let COUNTER=COUNTER+1
    echo -n "."
    sleep 1
done

echo -e "\n\nDeploying nginx via Argo CD.\n"
kubectl create namespace web-services >> $LOG_FILE 2>&1
argocd app create nginx-$RANDOM_NAME --repo https://github.com/bwilliam79/Komodor-App.git --dest-server https://kubernetes.default.svc --path nginx --dest-namespace web-services >> $LOG_FILE 2>&1
argocd app set nginx-$RANDOM_NAME --sync-option Replace=true >> $LOG_FILE 2>&1
argocd app sync nginx-$RANDOM_NAME >> $LOG_FILE 2>&1

echo -en "Waiting for nginx deployment to complete."
until kubectl get pods -n web-services | grep nginx | grep -i 'running' | grep 1/1 >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done

echo -e "\n\nSetting up port forward for nginx."
kubectl port-forward --address 0.0.0.0 svc/nginx-$RANDOM_NAME -n web-services 8088:80 > /dev/null 2>&1 &

printf "You can now access the Argo CD dashboard at \033[33;32mhttp://$HOSTNAME:8080\033[33;37m\n"
echo -e "\nUsername: admin"
echo -e "Password: $ARGOCD_PASSWORD\n"

printf "You can now access the nginx deployment at \033[33;32mhttp://$HOSTNAME:8088\033[33;37m\n"

echo -e "\nDeployment name: nginx-$RANDOM_NAME"