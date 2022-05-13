#!/usr/bin/env bash

# Setup Items
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

firewall-cmd --add-port=6443/tcp --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --reload

cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# CRI-O Installation
export OS=CentOS_8_Stream
export VERSION=1.23

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo

dnf install -y cri-o cri-tools iproute-tc

systemctl daemon-reload
systemctl enable crio --now

# Kubernetes tools
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

# k8s config
curl -o yq -fsSL https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64 && chmod +x yq && mv yq /usr/local/bin/
cat <<EOF | tee k8s-script.sh
#!/bin/bash

set -euo pipefail

KUBEADM_CONFIG="${1-/tmp/kubeadm.yaml}"
echo "Printing to $KUBEADM_CONFIG"

if [ -d "$KUBEADM_CONFIG" ]; then
    echo "$KUBEADM_CONFIG is a directory!"
    exit 1
fi

if [ ! -d $(dirname "$KUBEADM_CONFIG") ]; then
    echo "please create directory $(dirname $KUBEADM_CONFIG)"
    exit 1
fi

if [ ! $(which yq) ]; then
    echo "please install yq"
    exit 1
fi

if [ ! $(which kubeadm) ]; then
    echo "please install kubeadm"
    exit 1
fi

kubeadm config print init-defaults --component-configs=KubeletConfiguration > "$KUBEADM_CONFIG"
yq -i eval 'select(.nodeRegistration.criSocket) |= .nodeRegistration.criSocket = "unix:///var/run/crio/crio.sock"' "$KUBEADM_CONFIG"
EOF

export CIDR=10.85.0.0/16
