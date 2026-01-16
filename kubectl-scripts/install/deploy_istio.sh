#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="istio-system"

echo "🔍 Validating kubectl access..."
kubectl cluster-info >/dev/null 2>&1 || {
  echo "❌ Cannot access Kubernetes cluster"
  exit 1
}

echo "🔍 Checking Helm..."
command -v helm >/dev/null 2>&1 || {
  echo "❌ Helm not installed"
  exit 1
}

echo "📦 Adding Istio Helm repo (if missing)..."
helm repo list | grep -q '^istio' || \
  helm repo add istio https://istio-release.storage.googleapis.com/charts

echo "🔄 Updating Helm repos..."
helm repo update

echo "📁 Ensuring namespace exists..."
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || \
  kubectl create namespace "$NAMESPACE"

echo "🧱 Installing / upgrading istio-base (CRDs)..."
helm upgrade --install istio-base istio/base \
  -n "$NAMESPACE" \
  --wait

echo "🧠 Installing / upgrading istiod (control plane)..."
helm upgrade --install istiod istio/istiod \
  -n "$NAMESPACE" \
  --wait \
  --set resources.requests.memory=10Mi \
  --set resources.limits.memory=100Mi

echo "🌐 Installing / upgrading ingress gateway..."
helm upgrade --install istio-ingressgateway istio/gateway \
  -n "$NAMESPACE" \
  --wait

echo "✅ Verifying Istio pods..."
kubectl get pods -n "$NAMESPACE"

echo "🎉 Istio installation complete"
