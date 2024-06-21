#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Komodor demo environment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=./nginx-deploy.log

echo -e "Logging in to Argo CD\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_PASSWORD > $LOG_FILE 2>&1

echo -e "Deploying nginx via Argo CD.\n"
kubectl create namespace web-services >> $LOG_FILE 2>&1
argocd app create nginx --repo https://github.com/bwilliam79/Komodor-App.git --dest-server https://kubernetes.default.svc --path nginx --dest-namespace web-services >> $LOG_FILE 2>&1
argocd app set nginx --sync-option Replace=true >> $LOG_FILE 2>&1
argocd app sync nginx >> $LOG_FILE 2>&1

echo -en "Waiting for nginx deployment to complete."
until kubectl get pods -n web-services | grep nginx | grep -i 'running' | grep 1/1 >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done

#echo -e "\n\nSetting up port forward for nginx.\n"
#kubectl port-forward --address 0.0.0.0 svc/nginx -n web-services 8088:80 > /dev/null 2>&1 &

printf "\n\nYou can now access the nginx deployment at \033[33;32mhttp://$HOSTNAME\033[33;37m\n"