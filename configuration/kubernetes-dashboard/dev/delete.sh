#!/bin/bash
# Author: juandisay

echo "install dashboard"
kubectl delete -f namespace.yaml -f kubernetes-dashboard.yaml -f metric-scraper.yaml

echo "set user admin"
kubectl delete -f admin-token.yaml
