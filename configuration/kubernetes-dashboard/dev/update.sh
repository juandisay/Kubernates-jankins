#!/bin/bash
# Author: juandisay

echo "install dashboard"
kubectl apply -f namespace.yaml -f kubernetes-dashboard.yaml -f metric-scraper.yaml

echo "set user admin"
kubectl apply -f admin-token.yaml
