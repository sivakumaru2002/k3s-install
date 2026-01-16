#!/usr/bin/env bash
set -euo pipefail

############################################
# CONFIG
############################################

DASHBOARD_VERSION="v2.7.0"

############################################
# UTILS
############################################

log() {
  echo -e "\n[INFO] $1\n"
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script with sudo"
    exit 1
  fi

  if [[ -z "${SUDO_USER:-}" ]]; then
    echo "SUDO_USER not set. Run using: sudo ./deploy-k3s-server.sh"
    exit 1
  fi
}

wait_for_api() {
  log "Waiting for Kubernetes API to become ready..."
  until kubectl get nodes &>/dev/null; do
    sleep 2
  done
}

############################################
# INSTALL K3S SERVER
############################################

install_k3s() {
  if systemctl is-active --quiet k3s; then
    log "K3s already running, skipping install"
    return
  fi

  log "Installing K3s server"
  curl -sfL https://get.k3s.io | sh -
}

############################################
# KUBECTL CONFIG
############################################

configure_kubectl() {
  log "Configuring kubectl for user: $SUDO_USER"

  USER_HOME=$(eval echo "~$SUDO_USER")

  mkdir -p "$USER_HOME/.kube"
  cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
  chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.kube/config"
  chmod 600 "$USER_HOME/.kube/config"

  export KUBECONFIG="$USER_HOME/.kube/config"

  if ! grep -q KUBECONFIG "$USER_HOME/.bashrc"; then
    echo 'export KUBECONFIG=$HOME/.kube/config' >> "$USER_HOME/.bashrc"
  fi
}

############################################
# DASHBOARD
############################################

install_dashboard() {
  log "Installing Kubernetes Dashboard"

  kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml


    kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard \
    -p '{
        "spec": {
        "type": "NodePort",
        "ports": [
            {
            "port": 443,
            "targetPort": 8443,
            "protocol": "TCP",
            "nodePort": 32608
            }
        ]
        }
    }'

}

create_admin_user() {
  log "Creating admin ServiceAccount"

  kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  log "Dashboard admin token:"
  kubectl -n kubernetes-dashboard create token admin-user
}

############################################
# MAIN
############################################

require_root
install_k3s
configure_kubectl
wait_for_api

./deploy_helm.sh
./deploy_istio.sh
kubectl get nodes

install_dashboard
create_admin_user


export KUBECONFIG=$HOME/.kube/config
kubectl config current-context

log "K3s single-node cluster is ready"
