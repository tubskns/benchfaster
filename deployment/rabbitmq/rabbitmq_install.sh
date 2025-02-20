#!/bin/bash

PAYLOAD_DIR=/tmp/benchfaster/payload

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for worker in $(sudo -E kubectl get nodes | grep -v control-plane | grep -v NAME | sed 's/\s.*$//'); do
    sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
done
sudo -E kubectl apply -f ${PAYLOAD_DIR}/rabbitmq-ns.yaml
sudo -E kubectl apply -f ${PAYLOAD_DIR}/memory-defaults.yaml --namespace=rabbitmq
sudo -E kubectl apply -f ${PAYLOAD_DIR}/rabbitmq-configmap.yaml
sudo -E kubectl apply -f ${PAYLOAD_DIR}/rabbitmq.yaml
sudo -E kubectl apply -f ${PAYLOAD_DIR}/rabbitmq-svc.yaml
sudo -E kubectl -n rabbitmq rollout status -w deployment/rabbitmq
sudo -E kubectl autoscale deployment rabbitmq -n rabbitmq --cpu-percent=50 --min=1 --max=$1
sleep 20
