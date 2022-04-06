#!/bin/bash

set -x

kubectl create namespace development
kubectl -n development apply -f ./eks_standard_storage_class.yaml
echo "--------------------------"
echo " Storage Classes          "
echo "--------------------------"
kubectl get storageclasses -o wide

cat <<EOF > /tmp/awscreds.sh
apiVersion: v1
kind: Secret
metadata:
  name: aws-secret
  namespace: kube-system
stringData:
  key_id: "AKIAWNTEZWY3AQESPOVH"
  access_key: "Gx274n/q6opVUDhWrINogLz4MLtN9Og0oJEjIZiz"
EOF

kubectl -n development create serviceaccount aerospike-operator-controller-manager

tempSA=$(kubectl get clusterrolebindings.rbac.authorization.k8s.io -o name --all-namespaces \
 | grep aerospike-kubernetes-operator.v2.0.0 \
 | grep -v aerospike-kubernetes-operator.v2.0.0-aerospike-opera)

# Service Account doesn't exist so patch it in
kubectl patch $tempSA \
--type='json' \
-p='[{"op": "add", "path": "/subjects/1", "value": {"kind": "ServiceAccount", "name": "aerospike-operator-controller-manager","namespace": "development" } }]'

kubectl describe $tempSA

kubectl apply -f /tmp/awscreds.sh
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.5"
