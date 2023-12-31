#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./argocd-deploy.log

echo -e "Enter k8s cluster name:"
read K8S_CLUSTER_NAME

echo -e "\nDeploying Argo CD.\n"
kubectl create namespace argocd > $LOG_FILE 2>&1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >> $LOG_FILE 2>&1

sleep 5

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
argocd cluster add $K8S_CLUSTER_NAME -y >> $LOG_FILE 2>&1

printf "You can now access the Argo CD dashboard at \033[33;32mhttp://$HOSTNAME:8080\033[33;37m\n"
echo -e "\nUsername: admin"
echo -e "Password: $ARGOCD_PASSWORD\n"