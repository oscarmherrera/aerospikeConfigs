#!/usr/bin/env bash
set -x
# Usage: kubesudo namespace:serviceaccount get pod

USAGE="Usage: $0 [namespace:]user kubectl-commands..."

if [ "$#" == "0" ]; then
    echo "$USAGE"
    exit 1
fi

SA=$1
shift

if [[ $SA = *":"* ]]; then
    arrSA=(${SA//:/ })
    NAMESPACE=${arrSA[0]}
    SA=${arrSA[1]}
else
    NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
fi

if [ -z "$NAMESPACE" ]
then
    NAMESPACE=default
fi

TMPKUBE=$(mktemp)

kubectl config view --flatten --minify > $TMPKUBE

export KUBECONFIG=$TMPKUBE

SECRET=$(kubectl -n $NAMESPACE get sa $SA -o go-template='{{range .secrets}}{{println .name}}{{end}}' | grep token)
TOKEN=$(kubectl -n $NAMESPACE get secret ${SECRET} -o go-template='{{.data.token}}')

kubectl config set-credentials kubesudo:$NAMESPACE:$SA \
    --token=`echo ${TOKEN} | base64 -d` > /dev/null

kubectl config set-context $(kubectl config current-context) --user=kubesudo:$NAMESPACE:$SA > /dev/null

kubectl --kubeconfig=$TMPKUBE $@

rm $TMPKUBE
