#!/bin/bash
# Copyright 2022 Nordcloud Oy or its affiliates. All Rights Reserved.

set -eE -o pipefail
shopt -s extdebug

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
GITHUB_SHA="$(git rev-parse --short=7 HEAD)"

readonly NAMESPACE='capact-system'
readonly WORKSPACE
readonly GITHUB_SHA

echo "Install/Upgrade neo4j release"
helm -n "${NAMESPACE}" upgrade --install --wait neo4j "${WORKSPACE}"/charts/neo4j

echo "Install/Upgrade ingress-nginx release"
helm -n "${NAMESPACE}" upgrade --install --wait ingress-nginx "${WORKSPACE}"/charts/ingress-controller

echo "Install/Upgrade argo release"
if ! helm -n "${NAMESPACE}" get notes argo > /dev/null 2>&1; then
   helm -n "${NAMESPACE}" install argo "${WORKSPACE}"/charts/argo
else
   ACCESS_KEY=$(kubectl get secret --namespace "capact-system" argo-minio -o jsonpath="{.data.access-key}" | base64 --decode)
   SECRET_KEY=$(kubectl get secret --namespace "capact-system" argo-minio -o jsonpath="{.data.secret-key}" | base64 --decode)
   helm -n "${NAMESPACE}" upgrade --install --wait argo "${WORKSPACE}"/charts/argo --set minio.accessKey.password="${ACCESS_KEY}" --set minio.secretKey.password="${SECRET_KEY}"
fi

echo "Install/Upgrade cert-manager release"
helm -n "${NAMESPACE}" upgrade --install --wait cert-manager "${WORKSPACE}"/charts/cert-manager

echo "Install/Upgrade kubed release"
helm -n "${NAMESPACE}" upgrade --install --wait kubed "${WORKSPACE}"/charts/kubed

echo "Install/Upgrade capact release"
helm -n "${NAMESPACE}" upgrade --install --wait capact "${WORKSPACE}"/charts/capact --set global.containerRegistry.overrideTag="${GITHUB_SHA}"

helm list -n "${NAMESPACE}"