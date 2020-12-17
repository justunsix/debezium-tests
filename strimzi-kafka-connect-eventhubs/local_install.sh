#!/bin/bash

# Script to store all commands for local installation of Strimzi and Debezium using files in this repository

export STRIMZI_VERSION=0.20.0
git clone -b $STRIMZI_VERSION https://github.com/strimzi/strimzi-kafka-operator
cd strimzi-kafka-operator

# Switch to an admin user to create security objects as part of installation:
# oc login -u system:admin # Required for remote Openshift instance, not required for local kuberctl

kubectl create -f install/cluster-operator && kubectl create -f examples/templates/cluster-operator
docker build -t justintungonline/strimzi-kafka-connect-debezium:latest .
docker push justintungonline/strimzi-kafka-connect-debezium:latest

# Kubernetes namespace cdc-kafka
kubectl apply -f eventhubs-secret.yaml
kubectl -n cdc-kafka create secret generic sql-credentials --from-file=sqlserver-credentials.properties
kubectl apply -f kafka-connect.yaml -n cdc-kafka
kubectl get pods -n cdc-kafka