# Cấu hình chi tiết Kubernetes Cluster với Calico

## Tổng quan
Tài liệu này mô tả chi tiết các cấu hình của Kubernetes cluster với Calico networking.

## 1. Cấu hình Network

### 1.1 Calico CNI Configuration
Calico được cấu hình với các thông số sau:

```yaml
# Calico CNI Configuration
kube_network_plugin: calico
calico_version: v3.26.1
calico_typha_enabled: false
calico_typha_replicas: 0

# Network Configuration
kube_service_addresses: 10.233.0.0/18
kube_pods_subnet: 10.233.64.0/18
kube_network_node_prefix: 24

# Calico IP Pool Configuration
calico_ip_auto_method: "kubernetes-internal-ip"
calico_ipv4pool_cidr: "10.233.64.0/18"
calico_ipv4pool_ipip: "CrossSubnet"
calico_ipv4pool_vxlan: "Never"
```

**Giải thích các thông số:**
- `calico_version`: Phiên bản Calico sử dụng
- `calico_typha_enabled`: Tắt Typha cho cluster nhỏ
- `kube_service_addresses`: Dải IP cho Kubernetes services
- `kube_pods_subnet`: Dải IP cho pods
- `calico_ipv4pool_ipip`: Sử dụng IPIP mode cho cross-subnet communication
- `calico_ipv4pool_vxlan`: Tắt VXLAN mode

### 1.2 IP Pool Configuration
```yaml
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
```

**Giải thích:**
- `blockSize: 26`: Mỗi node được cấp 64 IP addresses (2^6)
- `ipipMode: CrossSubnet`: Sử dụng IPIP tunnel cho cross-subnet traffic
- `natOutgoing: true`: NAT cho traffic ra ngoài
- `nodeSelector: all()`: Áp dụng cho tất cả nodes

### 1.3 BGP Configuration
```yaml
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: true
  asNumber: 64512
```

**Giải thích:**
- `nodeToNodeMeshEnabled: true`: Bật full-mesh BGP giữa các nodes
- `asNumber: 64512`: AS number cho BGP routing

## 2. Cấu hình Container Runtime

### 2.1 Containerd Configuration
```yaml
container_manager: containerd
containerd_use_systemd_cgroup: true
```

**File cấu hình containerd:** `/etc/containerd/config.toml`
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

### 2.2 Cgroup Driver Configuration
```yaml
kubelet_cgroup_driver: systemd
```

## 3. Cấu hình Kubelet

### 3.1 Resource Management
```yaml
kubelet_eviction_hard: "memory.available<100Mi,nodefs.available<10%"
kubelet_eviction_soft: "memory.available<200Mi,nodefs.available<15%"
kubelet_eviction_soft_grace_period: "memory.available=30s,nodefs.available=30s"
```

**Giải thích:**
- `eviction_hard`: Ngưỡng cứng để evict pods
- `eviction_soft`: Ngưỡng mềm để evict pods
- `eviction_soft_grace_period`: Thời gian chờ trước khi evict

### 3.2 Kubelet Configuration File
```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
clusterDNS:
- 10.233.0.10
clusterDomain: cluster.local
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
failSwapOn: false
```

## 4. Cấu hình Security

### 4.1 RBAC Configuration
```yaml
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
```

### 4.2 Network Policies
```yaml
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
```

### 4.3 Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## 5. Cấu hình Storage

### 5.1 Local Storage Class
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### 5.2 Persistent Volume Example
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - master
```

## 6. Cấu hình Load Balancer

### 6.1 MetalLB Configuration
```yaml
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
```

### 6.2 Service Configuration
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: nginx
```

## 7. Cấu hình Monitoring

### 7.1 Resource Quotas
```yaml
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
```

### 7.2 Limit Ranges
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: default
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
```

## 8. Cấu hình DNS

### 8.1 CoreDNS Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

## 9. Cấu hình Logging

### 9.1 Fluentd Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch.logging
      port 9200
      logstash_format true
      logstash_prefix k8s
    </match>
```

## 10. Backup và Recovery

### 10.1 etcd Backup
```bash
# Backup etcd
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/admin-master.pem \
  --key=/etc/ssl/etcd/ssl/admin-master-key.pem \
  snapshot save /backup/etcd-snapshot-$(date +%Y%m%d_%H%M%S).db

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir /var/lib/etcd-restored
```

### 10.2 Cluster Backup Script
```bash
#!/bin/bash
# Backup Kubernetes resources
kubectl get all --all-namespaces -o yaml > /backup/k8s-resources-$(date +%Y%m%d_%H%M%S).yaml
kubectl get pv,pvc --all-namespaces -o yaml > /backup/storage-$(date +%Y%m%d_%H%M%S).yaml
```

## Kết luận
Các cấu hình trên đảm bảo:
- Network security với Calico policies
- Resource management hiệu quả
- High availability với proper backup
- Monitoring và logging đầy đủ
- Scalability cho production workloads 