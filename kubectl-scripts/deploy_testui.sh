#!/usr/bin/env bash
set -euo pipefail

RELEASE_NAME="testui"
NAMESPACE="testui"
CHART_PATH="../helm-charts/helm-chart-testui"
VALUES_FILE="../helm-charts/helm-chart-testui/values.yaml"
IMAGE_TAG="testui.container.tag=stage_68523"

echo "Checking namespace: ${NAMESPACE}"
if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  echo "Creating namespace: ${NAMESPACE}"
  kubectl create namespace "${NAMESPACE}"
else
  echo "Namespace already exists: ${NAMESPACE}"
fi

./docker_creds.sh "${NAMESPACE}"

echo "Deploying Helm release: ${RELEASE_NAME}"

helm upgrade --install "${RELEASE_NAME}" \
  -f "${VALUES_FILE}" \
  "${CHART_PATH}" \
  -n "${NAMESPACE}" \
  --set "${IMAGE_TAG}"

kubectl patch serviceaccount default \
  -n "${NAMESPACE}" \
  -p '{"imagePullSecrets":[{"name":"acr-secret"}]}'


kubectl delete pod -n testui --all

echo "✅ Deployment completed successfully"
