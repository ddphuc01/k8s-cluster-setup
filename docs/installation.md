# Hướng dẫn cài đặt chi tiết Kubernetes Cluster

## 📋 Mục lục

1. [Chuẩn bị môi trường](#chuẩn-bị-môi-trường)
2. [Cấu hình inventory](#cấu-hình-inventory)
3. [Cài đặt cluster cơ bản](#cài-đặt-cluster-cơ-bản)
4. [Cài đặt monitoring stack](#cài-đặt-monitoring-stack)
5. [Cài đặt Rancher (tùy chọn)](#cài-đặt-rancher-tùy-chọn)
6. [Xác minh cài đặt](#xác-minh-cài-đặt)
7. [Troubleshooting](#troubleshooting)

## 🔧 Chuẩn bị môi trường

### Yêu cầu hệ thống

#### Master Node
- **CPU**: Tối thiểu 2 cores, khuyến nghị 4 cores
- **RAM**: Tối thiểu 4GB, khuyến nghị 8GB
- **Disk**: Tối thiểu 50GB, khuyến nghị 100GB SSD
- **Network**: 1Gbps ethernet

#### Worker Nodes
- **CPU**: Tối thiểu 2 cores, khuyến nghị 4 cores
- **RAM**: Tối thiểu 4GB, khuyến nghị 16GB
- **Disk**: Tối thiểu 50GB, khuyến nghị 200GB SSD
- **Network**: 1Gbps ethernet

### Cài đặt dependencies

#### Trên máy control (máy chạy Ansible)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3 python3-pip git ansible

# CentOS/RHEL
sudo yum install -y python3 python3-pip git ansible

# Cài đặt Python packages
pip3 install --user ansible netaddr jinja2 ruamel.yaml cryptography
```

#### Trên tất cả nodes

```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Cấu hình kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

# Load modules
sudo modprobe br_netfilter
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe nf_conntrack

# Cấu hình sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

### Cấu hình SSH

```bash
# Tạo SSH key (nếu chưa có)
ssh-keygen -t rsa -b 4096 -C "your-email@domain.com"

# Copy SSH key đến tất cả nodes
ssh-copy-id user@master-ip
ssh-copy-id user@worker1-ip
ssh-copy-id user@worker2-ip

# Test SSH connectivity
ssh user@master-ip "sudo whoami"
ssh user@worker1-ip "sudo whoami"
ssh user@worker2-ip "sudo whoami"
```

## 📝 Cấu hình inventory

### Tạo inventory file

Chỉnh sửa `inventory/hosts.yml`:

```yaml
all:
  hosts:
    # Master node
    k8s-master:
      ansible_host: 192.168.1.10
      ip: 192.168.1.10
      access_ip: 192.168.1.10
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
    
    # Worker nodes
    k8s-worker1:
      ansible_host: 192.168.1.11
      ip: 192.168.1.11
      access_ip: 192.168.1.11
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
    
    k8s-worker2:
      ansible_host: 192.168.1.12
      ip: 192.168.1.12
      access_ip: 192.168.1.12
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa

  children:
    kube_control_plane:
      hosts:
        k8s-master:
    
    kube_node:
      hosts:
        k8s-worker1:
        k8s-worker2:
    
    etcd:
      hosts:
        k8s-master:
    
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    
    calico_rr:
      hosts: {}
```

### Kiểm tra connectivity

```bash
# Test Ansible connectivity
ansible all -i inventory/hosts.yml -m ping

# Kiểm tra sudo access
ansible all -i inventory/hosts.yml -m shell -a "sudo whoami" -b
```

## 🚀 Cài đặt cluster cơ bản

### Option 1: Sử dụng script tự động

```bash
# Cài đặt cluster cơ bản
./install.sh

# Hoặc với các tùy chọn
./install.sh --help
```

### Option 2: Cài đặt từng bước

#### Bước 1: Pre-installation

```bash
./scripts/pre-install.sh
```

Script này sẽ:
- Kiểm tra system requirements
- Cấu hình SSH keys
- Cài đặt dependencies
- Chuẩn bị kubespray

#### Bước 2: Chạy kubespray

```bash
./scripts/install-kubespray.sh
```

Quá trình này có thể mất 15-30 phút tùy thuộc vào:
- Tốc độ mạng
- Hiệu năng hardware
- Số lượng nodes

#### Bước 3: Post-installation

```bash
./scripts/post-install.sh
```

Script này sẽ:
- Cấu hình kubectl
- Cài đặt Helm
- Thiết lập storage classes
- Cấu hình network policies

### Xác minh cài đặt cơ bản

```bash
# Kiểm tra nodes
kubectl get nodes -o wide

# Kiểm tra system pods
kubectl get pods -n kube-system

# Kiểm tra cluster info
kubectl cluster-info

# Test tạo pod
kubectl run test-pod --image=nginx --rm -it --restart=Never -- curl -I http://kubernetes.default.svc.cluster.local
```

## 📊 Cài đặt monitoring stack

### Cài đặt tự động

```bash
# Cài đặt complete monitoring stack
./scripts/install-complete-monitoring.sh

# Hoặc từng component
./scripts/install-monitoring-stack.sh
```

### Cài đặt thủ công

#### Bước 1: Tạo namespace

```bash
kubectl create namespace monitoring
```

#### Bước 2: Cài đặt Prometheus

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values manifests/monitoring/prometheus-values.yaml
```

#### Bước 3: Cài đặt Grafana

```bash
# Grafana đã được cài cùng với Prometheus stack
# Cấu hình dashboards
kubectl apply -f manifests/monitoring/grafana-dashboards-config.yaml
```

#### Bước 4: Cài đặt Loki

```bash
# Add Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values manifests/monitoring/loki-values.yaml
```

#### Bước 5: Cấu hình Ingress

```bash
# Cài đặt NGINX Ingress Controller
./scripts/install-ingress.sh

# Apply ingress rules
kubectl apply -f manifests/monitoring/prometheus-ingress.yaml
kubectl apply -f manifests/monitoring/grafana-ingress.yaml
kubectl apply -f manifests/monitoring/alertmanager-ingress.yaml
```

### Truy cập monitoring services

#### Grafana

```bash
# Lấy admin password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward (nếu chưa có ingress)
kubectl port-forward --namespace monitoring svc/grafana 3000:80
```

Truy cập: http://localhost:3000
- Username: admin
- Password: từ lệnh trên

#### Prometheus

```bash
# Port forward
kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Truy cập: http://localhost:9090

#### AlertManager

```bash
# Port forward
kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

Truy cập: http://localhost:9093

## 🎛️ Cài đặt Rancher (tùy chọn)

### Cài đặt tự động

```bash
./scripts/install-rancher-complete.sh
```

### Cài đặt thủ công

#### Bước 1: Cài đặt cert-manager

```bash
./scripts/install-cert-manager.sh
```

#### Bước 2: Cài đặt Rancher

```bash
# Add Rancher Helm repo
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Create namespace
kubectl create namespace cattle-system

# Install Rancher
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.your-domain.com \
  --set bootstrapPassword=admin123456 \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=your-email@domain.com
```

#### Bước 3: Truy cập Rancher

```bash
# Kiểm tra trạng thái
kubectl -n cattle-system rollout status deploy/rancher

# Lấy URL
echo "https://rancher.your-domain.com"
```

## ✅ Xác minh cài đặt

### Kiểm tra tổng quan

```bash
# Chạy script kiểm tra
./scripts/check-monitoring-stack.sh
```

### Kiểm tra từng component

```bash
# Nodes
kubectl get nodes -o wide

# Pods trong tất cả namespaces
kubectl get pods --all-namespaces

# Services
kubectl get svc --all-namespaces

# Ingress
kubectl get ingress --all-namespaces

# Storage classes
kubectl get storageclass

# Persistent volumes
kubectl get pv,pvc --all-namespaces
```

### Test workload

```bash
# Deploy test application
kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --port=80 --type=ClusterIP

# Test service discovery
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup nginx-test

# Cleanup
kubectl delete deployment nginx-test
kubectl delete service nginx-test
```

## 🔧 Troubleshooting

### Lỗi thường gặp

#### 1. Nodes NotReady

```bash
# Kiểm tra node status
kubectl describe node <node-name>

# Kiểm tra kubelet logs
sudo journalctl -u kubelet -f

# Restart kubelet
sudo systemctl restart kubelet
```

#### 2. Pods Pending/CrashLoopBackOff

```bash
# Kiểm tra pod details
kubectl describe pod <pod-name> -n <namespace>

# Xem logs
kubectl logs <pod-name> -n <namespace> --previous

# Kiểm tra resources
kubectl top nodes
kubectl top pods --all-namespaces
```

#### 3. Network issues

```bash
# Kiểm tra Calico pods
kubectl get pods -n kube-system | grep calico

# Test pod-to-pod connectivity
kubectl run test1 --image=busybox --rm -it --restart=Never -- ping <pod-ip>

# Kiểm tra DNS
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

#### 4. Storage issues

```bash
# Kiểm tra storage classes
kubectl get storageclass

# Kiểm tra PV/PVC
kubectl get pv,pvc --all-namespaces

# Describe PVC để xem lỗi
kubectl describe pvc <pvc-name> -n <namespace>
```

### Debug commands

```bash
# Cluster info
kubectl cluster-info dump

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# API server logs
sudo journalctl -u kube-apiserver -f

# Controller manager logs
sudo journalctl -u kube-controller-manager -f

# Scheduler logs
sudo journalctl -u kube-scheduler -f
```

### Logs locations

```bash
# Kubelet logs
sudo journalctl -u kubelet -f

# Container runtime logs (containerd)
sudo journalctl -u containerd -f

# Kubernetes audit logs
sudo tail -f /var/log/audit.log

# Application logs
kubectl logs -f <pod-name> -n <namespace>
```

## 📞 Hỗ trợ

Nếu gặp vấn đề trong quá trình cài đặt:

1. Kiểm tra [troubleshooting guide](troubleshooting.md)
2. Xem [GitHub Issues](https://github.com/ddphuc01/k8s-cluster-setup/issues)
3. Tạo issue mới với đầy đủ thông tin:
   - OS version
   - Hardware specs
   - Error logs
   - Steps to reproduce

---

**Chúc bạn cài đặt thành công! 🎉**
