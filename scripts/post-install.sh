#!/bin/bash

# Post-Installation Configuration Script
# Cấu hình bổ sung sau khi cài đặt Kubernetes cluster

set -e

echo "=== Post-Installation Configuration ==="
echo "Cấu hình bổ sung cho Kubernetes cluster..."

# Kiểm tra kubeconfig
if [ ! -f ~/.kube/config ]; then
    echo "Lỗi: Không tìm thấy kubeconfig file"
    exit 1
fi

# Kiểm tra cluster
echo "1. Kiểm tra cluster status..."
kubectl get nodes
kubectl get pods -A

# Cấu hình Calico IP Pool
echo "2. Cấu hình Calico IP Pool..."
cat << EOF | kubectl apply -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  blockSize: 26
  cidr: 10.233.64.0/18
  ipipMode: CrossSubnet
  natOutgoing: true
  nodeSelector: all()
  vxlanMode: Never
EOF

# Cấu hình Calico BGP (tùy chọn)
echo "3. Cấu hình Calico BGP..."
cat << EOF | kubectl apply -f -
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: true
  asNumber: 64512
EOF

# Cài đặt MetalLB (Load Balancer)
echo "4. Cài đặt MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Cấu hình MetalLB IP Pool
cat << EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.200-192.168.56.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF

# Cài đặt NGINX Ingress Controller
echo "5. Cài đặt NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Cấu hình default storage class
echo "6. Cấu hình default storage class..."
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Tạo namespace cho applications
echo "7. Tạo namespaces..."
kubectl create namespace monitoring
kubectl create namespace logging
kubectl create namespace ingress-nginx

# Cấu hình resource quotas
echo "8. Cấu hình resource quotas..."
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: default
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
EOF

# Cấu hình Network Policies
echo "9. Cấu hình Network Policies..."
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Cấu hình RBAC
echo "10. Cấu hình RBAC..."
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admin-user
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user-binding
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: default
roleRef:
  kind: ClusterRole
  name: admin-user
  apiGroup: rbac.authorization.k8s.io
EOF

# Tạo ServiceAccount cho admin
kubectl create serviceaccount admin-user

# Kiểm tra cấu hình
echo "11. Kiểm tra cấu hình..."
echo "=== Cluster Information ==="
kubectl cluster-info
echo ""
echo "=== Node Information ==="
kubectl get nodes -o wide
echo ""
echo "=== Pod Information ==="
kubectl get pods -A
echo ""
echo "=== Service Information ==="
kubectl get svc -A
echo ""
echo "=== Storage Classes ==="
kubectl get storageclass
echo ""
echo "=== Network Policies ==="
kubectl get networkpolicies -A

echo "=== Post-installation configuration hoàn thành ==="
echo ""
echo "Cluster đã được cấu hình đầy đủ với:"
echo "- Calico networking với IPIP mode"
echo "- MetalLB load balancer"
echo "- NGINX Ingress Controller"
echo "- Local storage class"
echo "- Network policies"
echo "- RBAC configuration"
echo ""
echo "Để test cluster, chạy:"
echo "kubectl run nginx --image=nginx --port=80"
echo "kubectl expose pod nginx --type=LoadBalancer --port=80" 