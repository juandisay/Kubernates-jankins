#!/bin/bash
# Author: juandisay

echo "install dashboard"
kubectl create -f ./namespace.yaml -f ./kubernetes-dashboard.yaml -f ./metric-scraper.yaml

echo "set user admin"
kubectl create -f ./admin-token.yaml
