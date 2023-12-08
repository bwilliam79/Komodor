#!/bin/bash
# 12/07/2023 - Brandon Williams
# Shell script to speed up Minikube and Argo CD deployment

# Password to use for Argo CD admin account
ARGOCD_PASSWORD="Komodor!"

# Log file for output
LOG_FILE=~/argocd-deploy-komodor.log

# Install kubectl and helm
#echo -e "Installing kubectl and helm.\n"
#sudo snap install kubectl --classic 2>&1 > $LOG_FILE
#sudo snap install helm --classic 2>&1 >> $LOG_FILE

#shopt -s expand_aliases
#alias kubectl="minikube kubectl --"

echo -e "Deploying Argo CD.\n"
kubectl create namespace argocd > $LOG_FILE 2>&1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >> $LOG_FILE 2>&1

echo -en "Waiting for Argo CD deployment to complete."
until kubectl get pods -n argocd | grep argocd-server | grep -i 'running' >> $LOG_FILE 2>&1
do
    echo -n "."
    sleep 2
done

echo -e "\n\nSetting up port forward for Argo CD API server."
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

ARGOCD_INITIAL_PASSWORD=`argocd admin initial-password -n argocd | head -n 1`

echo -e "\nLogging in to Argo CD to change initial password.\n"
argocd login komodor:8080 --insecure --username admin --password $ARGOCD_INITIAL_PASSWORD >> $LOG_FILE 2>&1
argocd account update-password --current-password $ARGOCD_INITIAL_PASSWORD --new-password $ARGOCD_PASSWORD >> $LOG_FILE 2>&1

echo -e "Registering minikube cluster with Argo CD.\n"
argocd cluster add minikube >> $LOG_FILE 2>&1

echo -e "Deploying Komodor.\n"
#HELM_API_KEY=11ab1ef7-673b-4064-ad71-e9e0a944372d USER_EMAIL=brandon.williams79@gmail.com bash <(curl -s -Ls https://raw.githubusercontent.com/komodorio/Install/master/install.sh)
helm repo add komodorio https://helm-charts.komodor.io >> $LOG_FILE 2>&1
helm repo update >> $LOG_FILE 2>&1
helm upgrade --install k8s-watcher komodorio/k8s-watcher \
 --set apiKey=80f122f0-03e2-4c1a-bed0-74570a239975 \
 --set watcher.resources.secret=true \
 --set watcher.enableHelm=true \
 --set helm.enableActions=true \
 --set watcher.clusterName=minikube \
 --set watcher.enableAgentTaskExecution=true \
 --set watcher.allowReadingPodLogs=true >> $LOG_FILE 2>&1

 echo -en "Waiting for things to settle."
 COUNTER=0
 while [ $COUNTER -lt 10 ]; do
    let COUNTER=COUNTER+1
    echo -n "."
    sleep 1
done

#echo -e "\n\nDeploying example app on Argo CD.\n"
#kubectl config set-context --current --namespace=argocd >> $LOG_FILE 2>&1
#kubectl create namespace guestbook >> $LOG_FILE 2>&1
#argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace guestbook >> $LOG_FILE 2>&1
#argocd app sync guestbook >> $LOG_FILE 2>&1

echo -e "\n\nDeploying nginx via Argo CD.\n"
kubectl config set-context --current --namespace=argocd >> $LOG_FILE 2>&1
kubectl create namespace web-services >> $LOG_FILE 2>&1
argocd app create nginx --repo https://github.com/bwilliam79/Komodor-App.git --dest-server https://kubernetes.default.svc --dest-namespace web-services >> $LOG_FILE 2>&1
argocd app sync nginx >> $LOG_FILE 2>&1

printf "You can now access the Argo CD dashboard at \033[33;32mhttp://$HOSTNAME:8080\033[33;37m\n"
echo -e "\nUsername: admin"
echo -e "Password: $ARGOCD_PASSWORD\n"