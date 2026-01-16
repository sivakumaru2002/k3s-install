#!/usr/bin/env bash
set -euo pipefail

############################################
# USAGE
############################################
usage() {
  echo "Usage:"
  echo "  $0 <namespace>"
  echo ""
  echo "Required environment variables:"
  echo "  ACR_NAME"
  echo "  ACR_USERNAME"
  echo "  ACR_PASSWORD"
  exit 1
}

############################################
# INPUT
############################################
NAMESPACE="${1:-}"

if [[ -z "$NAMESPACE" ]]; then
  usage
fi

############################################
# CONFIG
############################################
SECRET_NAME="acr-secret"

############################################
# VALIDATION
############################################
error() {
  echo "❌ ERROR: $1" >&2
  exit 1
}

info() {
  echo "ℹ️  $1"
}

success() {
  echo "✅ $1"
}


ACR_NAME=
ACR_USERNAME=
ACR_PASSWORD=''

command -v kubectl >/dev/null 2>&1 || error "kubectl not found"

############################################
# CHECK NAMESPACE EXISTS
############################################
info "Checking namespace '$NAMESPACE'..."
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || error "Namespace '$NAMESPACE' does not exist"

############################################
# CHECK IF SECRET EXISTS
############################################
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  success "Secret '$SECRET_NAME' already exists in namespace '$NAMESPACE'. Nothing to do."
  exit 0
fi

############################################
# CREATE SECRET
############################################
info "Creating secret '$SECRET_NAME' in namespace '$NAMESPACE'..."

kubectl create secret docker-registry "$SECRET_NAME" \
  -n "$NAMESPACE" \
  --docker-server="${ACR_NAME}.azurecr.io" \
  --docker-username="$ACR_USERNAME" \
  --docker-password="$ACR_PASSWORD" 

success "Secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'."
