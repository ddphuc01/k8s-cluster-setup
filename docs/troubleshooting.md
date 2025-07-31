# Troubleshooting Kubernetes Cluster với Calico

## Tổng quan
Tài liệu này cung cấp các phương pháp xử lý sự cố thường gặp trong Kubernetes cluster với Calico networking.

## 1. Kiểm tra trạng thái cluster

### 1.1 Kiểm tra nodes
```bash
# Kiểm tra trạng thái nodes
kubectl get nodes -o wide

# Kiểm tra chi tiết node
kubectl describe node <node-name>

# Kiểm tra node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

### 1.2 Kiểm tra pods
```bash
# Kiểm tra tất cả pods
kubectl get pods -A

# Kiểm tra pods trong namespace cụ thể
kubectl get pods -n kube-system

# Kiểm tra chi tiết pod
kubectl describe pod <pod-name> -n <namespace>

# Kiểm tra logs của pod
kubectl logs <pod-name> -n <namespace>
```

### 1.3 Kiểm tra services
```bash
# Kiểm tra services
kubectl get svc -A

# Kiểm tra endpoints
kubectl get endpoints -A

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>
```

## 2. Network Troubleshooting

### 2.1 Kiểm tra Calico status
```bash
# Kiểm tra calico pods
kubectl get pods -n kube-system -l k8s-app=calico-node

# Kiểm tra calico logs
kubectl logs -n kube-system -l k8s-app=calico-node

# Kiểm tra calico IP pools
kubectl get ippool -o yaml

# Kiểm tra calico BGP peers
kubectl get bgppeers -o yaml

# Kiểm tra calico nodes
kubectl get caliconodes -o yaml
```

### 2.2 Kiểm tra network policies
```bash
# Kiểm tra network policies
kubectl get networkpolicies -A

# Kiểm tra chi tiết network policy
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### 2.3 Test network connectivity
```bash
# Test pod-to-pod communication
kubectl run test-pod1 --image=busybox --rm -it --restart=Never -- sh
# Trong pod 1
nslookup <service-name>
ping <pod-ip>

# Test external connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://google.com

# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

### 2.4 Kiểm tra iptables rules
```bash
# Trên node
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Kiểm tra calico rules
sudo iptables -L cali-INPUT -n -v
sudo iptables -L cali-FORWARD -n -v
```

## 3. Python Environment Issues

### 3.1 Externally-managed-environment Error
```bash
# Lỗi thường gặp trên Ubuntu 24.04+
error: externally-managed-environment

# Giải pháp: Chạy script fix Python environment
./scripts/fix-python-env.sh

# Hoặc tạo virtual environment thủ công
python3 -m venv kubespray-venv
source kubespray-venv/bin/activate
pip install ansible
```

### 3.2 Kiểm tra virtual environment
```bash
# Kiểm tra virtual environment
ls -la /opt/kubespray-venv/

# Activate virtual environment
source /opt/kubespray-venv/bin/activate

# Kiểm tra ansible version
ansible --version

# Deactivate virtual environment
deactivate
```

## 4. Container Runtime Issues

### 4.1 Kiểm tra containerd
```bash
# Kiểm tra containerd status
sudo systemctl status containerd

# Kiểm tra containerd logs
sudo journalctl -u containerd -f

# Kiểm tra containerd images
sudo ctr images list

# Kiểm tra containerd containers
sudo ctr containers list
```

### 3.2 Kiểm tra kubelet
```bash
# Kiểm tra kubelet status
sudo systemctl status kubelet

# Kiểm tra kubelet logs
sudo journalctl -u kubelet -f

# Kiểm tra kubelet configuration
sudo cat /var/lib/kubelet/config.yaml
```

## 4. Storage Issues

### 4.1 Kiểm tra storage classes
```bash
# Kiểm tra storage classes
kubectl get storageclass

# Kiểm tra persistent volumes
kubectl get pv

# Kiểm tra persistent volume claims
kubectl get pvc -A

# Kiểm tra chi tiết PV
kubectl describe pv <pv-name>
```

### 4.2 Kiểm tra local storage
```bash
# Kiểm tra disk space
df -h

# Kiểm tra inodes
df -i

# Kiểm tra mount points
mount | grep -E "(local|nfs|ceph)"
```

## 5. Security Issues

### 5.1 Kiểm tra RBAC
```bash
# Kiểm tra cluster roles
kubectl get clusterroles

# Kiểm tra cluster role bindings
kubectl get clusterrolebindings

# Kiểm tra service accounts
kubectl get serviceaccounts -A

# Test permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments
```

### 5.2 Kiểm tra certificates
```bash
# Kiểm tra certificate expiration
kubectl get secrets -n kube-system | grep tls

# Kiểm tra certificate details
kubectl get secret <secret-name> -n kube-system -o yaml

# Decode certificate
echo <base64-encoded-cert> | base64 -d | openssl x509 -text -noout
```

## 6. Performance Issues

### 6.1 Kiểm tra resource usage
```bash
# Kiểm tra node resources
kubectl top nodes

# Kiểm tra pod resources
kubectl top pods -A

# Kiểm tra container resources
kubectl top pods --containers -A
```

### 6.2 Kiểm tra system resources
```bash
# Kiểm tra CPU usage
top
htop

# Kiểm tra memory usage
free -h
cat /proc/meminfo

# Kiểm tra disk I/O
iostat -x 1

# Kiểm tra network usage
iftop
nethogs
```

## 7. Common Error Messages

### 7.1 Pod scheduling issues
```bash
# Kiểm tra pod events
kubectl describe pod <pod-name> -n <namespace>

# Kiểm tra node capacity
kubectl describe node <node-name>

# Kiểm tra taints and tolerations
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints[*].key}{"\n"}{end}'
```

### 7.2 Image pull issues
```bash
# Kiểm tra image pull secrets
kubectl get secrets -A | grep docker

# Kiểm tra registry connectivity
kubectl run test-pod --image=nginx --rm -it --restart=Never -- sh
```

### 7.3 Network connectivity issues
```bash
# Kiểm tra DNS resolution
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Kiểm tra service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Kiểm tra service selectors
kubectl get svc <service-name> -n <namespace> -o yaml
```

## 8. Recovery Procedures

### 8.1 Node recovery
```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Cordon/Uncordon node
kubectl cordon <node-name>
kubectl uncordon <node-name>

# Restart kubelet
sudo systemctl restart kubelet
```

### 8.2 Pod recovery
```bash
# Delete stuck pod
kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0

# Restart deployment
kubectl rollout restart deployment <deployment-name> -n <namespace>

# Scale deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=0
kubectl scale deployment <deployment-name> -n <namespace> --replicas=3
```

### 8.3 Cluster recovery
```bash
# Reset cluster (nếu cần)
ansible-playbook -i inventory/mycluster/hosts.yml \
    --become \
    --become-user=root \
    reset.yml

# Reinstall cluster
ansible-playbook -i inventory/mycluster/hosts.yml \
    --become \
    --become-user=root \
    cluster.yml
```

## 9. Monitoring và Logging

### 9.1 Kiểm tra logs
```bash
# Kiểm tra system logs
sudo journalctl -f

# Kiểm tra container logs
kubectl logs -f <pod-name> -n <namespace>

# Kiểm tra previous container logs
kubectl logs -f <pod-name> -n <namespace> --previous
```

### 9.2 Kiểm tra metrics
```bash
# Kiểm tra metrics server
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Kiểm tra prometheus (nếu có)
kubectl get pods -n monitoring -l app=prometheus
```

## 10. Best Practices

### 10.1 Regular maintenance
```bash
# Clean up completed jobs
kubectl delete jobs --field-selector status.successful=1

# Clean up evicted pods
kubectl delete pods --field-selector status.phase=Failed

# Clean up old images
sudo ctr images prune

# Clean up old logs
sudo journalctl --vacuum-time=7d
```

### 10.2 Backup procedures
```bash
# Backup etcd
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/ssl/etcd/ssl/ca.pem \
  --cert=/etc/ssl/etcd/ssl/admin-master.pem \
  --key=/etc/ssl/etcd/ssl/admin-master-key.pem \
  snapshot save /backup/etcd-snapshot-$(date +%Y%m%d_%H%M%S).db

# Backup cluster resources
kubectl get all --all-namespaces -o yaml > /backup/k8s-resources-$(date +%Y%m%d_%H%M%S).yaml
```

## Kết luận
Tài liệu này cung cấp các phương pháp troubleshooting cơ bản cho Kubernetes cluster. Để có hiệu quả tốt nhất:
- Luôn kiểm tra logs trước khi thực hiện các thao tác
- Sử dụng các lệnh diagnostic để xác định nguyên nhân
- Thực hiện backup trước khi thay đổi cấu hình
- Ghi chép lại các bước đã thực hiện để tham khảo sau này 