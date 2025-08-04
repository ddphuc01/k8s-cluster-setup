# Hướng dẫn truy cập và sử dụng Rancher

## 🌐 Truy cập Rancher UI

### Thông tin truy cập hiện tại
```bash
# URL truy cập
URL: https://rancher.local
External IP: 192.168.56.102
Ports: 80, 443

# Cấu hình DNS local (thêm vào /etc/hosts)
192.168.56.102 rancher.local
```

### Cách truy cập

#### 1. Cấu hình DNS local
```bash
# Thêm vào file /etc/hosts trên máy client
echo "192.168.56.102 rancher.local" | sudo tee -a /etc/hosts

# Hoặc trên Windows (C:\Windows\System32\drivers\etc\hosts)
192.168.56.102 rancher.local
```

#### 2. Lấy Bootstrap Password
```bash
# Chạy script để lấy thông tin truy cập
./scripts/rancher-status.sh

# Hoặc lấy trực tiếp
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'
```

#### 3. Truy cập Web UI
1. Mở trình duyệt và truy cập: `https://rancher.local`
2. Chấp nhận certificate warning (self-signed certificate)
3. Nhập Bootstrap Password từ bước 2
4. Thiết lập admin password mới
5. Xác nhận Server URL: `https://rancher.local`

## 🔧 Cấu hình ban đầu

### 1. Thiết lập Admin Password
- Username: `admin`
- Password: Thiết lập password mạnh (ít nhất 12 ký tự)
- Confirm Server URL: `https://rancher.local`

### 2. Import Local Cluster
Rancher sẽ tự động detect local cluster và import nó với tên "local".

### 3. Cấu hình User Management
```bash
# Tạo additional users (nếu cần)
# Thông qua Rancher UI: Users & Authentication > Users
```

## 📊 Dashboard và Monitoring

### 1. Cluster Overview
- **Nodes**: 2 (master + worker)
- **Pods**: Tổng số pods đang chạy
- **CPU/Memory**: Resource utilization
- **Storage**: PV/PVC status

### 2. Workloads Management
- **Deployments**: Quản lý applications
- **Services**: Network services
- **Ingress**: External access rules
- **ConfigMaps/Secrets**: Configuration management

### 3. Monitoring Integration
Rancher tự động tích hợp với monitoring stack hiện có:
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **AlertManager**: Alert notifications

## 🛠️ Quản lý Applications

### 1. App Catalog
```bash
# Truy cập Apps & Marketplace
# Deploy applications từ Helm charts
# Quản lý application lifecycle
```

### 2. Project/Namespace Management
```bash
# Tạo projects và namespaces
# Phân quyền user access
# Resource quotas và limits
```

### 3. Backup & Restore
```bash
# Cấu hình etcd snapshots
# Backup cluster configuration
# Disaster recovery procedures
```

## 🔐 Security và RBAC

### 1. Authentication
- **Local Authentication**: Built-in users
- **LDAP/AD Integration**: Enterprise authentication
- **SAML/OAuth**: Single sign-on

### 2. Authorization (RBAC)
```bash
# Cluster Roles
- Cluster Owner: Full cluster access
- Cluster Member: Limited cluster access
- Project Owner: Full project access
- Project Member: Limited project access

# Custom Roles
# Fine-grained permissions
```

### 3. Security Policies
- **Pod Security Policies**: Container security
- **Network Policies**: Traffic control
- **Resource Quotas**: Resource limits

## 🚨 Troubleshooting

### 1. Không thể truy cập Rancher UI
```bash
# Kiểm tra pods status
kubectl get pods -n cattle-system

# Kiểm tra services
kubectl get svc -n cattle-system

# Kiểm tra ingress
kubectl get ingress -n cattle-system

# Restart Rancher pods
kubectl rollout restart deployment/rancher -n cattle-system
```

### 2. Certificate Issues
```bash
# Kiểm tra cert-manager
kubectl get pods -n cert-manager

# Kiểm tra certificates
kubectl get certificates -n cattle-system

# Regenerate certificates
kubectl delete certificate rancher -n cattle-system
```

### 3. Performance Issues
```bash
# Kiểm tra resource usage
kubectl top pods -n cattle-system

# Scale Rancher replicas
kubectl scale deployment/rancher --replicas=3 -n cattle-system

# Check logs
kubectl logs -n cattle-system deployment/rancher
```

## 📈 Best Practices

### 1. Security
- Sử dụng strong passwords
- Enable 2FA khi có thể
- Regular security updates
- Network segmentation

### 2. Backup
- Regular etcd snapshots
- Backup Rancher configuration
- Test restore procedures
- Offsite backup storage

### 3. Monitoring
- Set up alerting rules
- Monitor resource usage
- Regular health checks
- Capacity planning

### 4. Updates
- Plan maintenance windows
- Test updates in staging
- Backup before updates
- Monitor after updates

## 🔗 Useful Links

- **Rancher Documentation**: https://rancher.com/docs/
- **Kubernetes Dashboard**: Accessible through Rancher UI
- **Monitoring Dashboards**: Integrated Grafana
- **API Documentation**: https://rancher.local/v3

---

**Lưu ý**: Tài liệu này dựa trên cấu hình thực tế của cluster hiện tại. Cập nhật thông tin khi có thay đổi cấu hình.
