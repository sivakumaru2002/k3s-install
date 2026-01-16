#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Checking prerequisites..."


if command -v helm >/dev/null 2>&1; then
  echo "⚠️ Helm already installed:"
  helm version
  exit 0
fi

INSTALL_SCRIPT="get_helm.sh"
HELM_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"

echo "⬇️ Downloading Helm installer..."
curl -fL --retry 3 --retry-delay 2 -o "$INSTALL_SCRIPT" "$HELM_URL"

if [[ ! -s "$INSTALL_SCRIPT" ]]; then
  echo "❌ Downloaded installer is empty or missing"
  exit 1
fi

chmod +x "$INSTALL_SCRIPT"

echo "🚀 Running Helm installer..."
if [[ $EUID -ne 0 ]]; then
  sudo ./"$INSTALL_SCRIPT"
else
  ./"$INSTALL_SCRIPT"
fi

echo "✅ Verifying Helm installation..."
if ! command -v helm >/dev/null 2>&1; then
  echo "❌ Helm installation completed but binary not found in PATH"
  exit 1
fi

helm version
echo "🎉 Helm installation successful"
