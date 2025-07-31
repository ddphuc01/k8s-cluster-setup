# Python Environment Fix - Ubuntu 24.04+

## Vấn đề
Trên Ubuntu 24.04+, Python sử dụng "externally-managed-environment" theo PEP 668, ngăn cản việc cài đặt packages trực tiếp với pip3.

### Lỗi thường gặp:
```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.

    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
```

## Giải pháp đã triển khai

### 1. Script tự động fix
Project này bao gồm script `scripts/fix-python-env.sh` để tự động xử lý vấn đề:

```bash
./scripts/fix-python-env.sh
```

### 2. Virtual Environment
Script sẽ tạo virtual environment tại `/opt/kubespray-venv`:

```bash
# Tạo virtual environment
sudo python3 -m venv /opt/kubespray-venv

# Cấu hình permissions
sudo chown -R $USER:$USER /opt/kubespray-venv

# Activate virtual environment
source /opt/kubespray-venv/bin/activate

# Cài đặt Ansible
pip install ansible
```

### 3. Alias tự động
Script tạo alias cho convenience:

```bash
alias ansible='/opt/kubespray-venv/bin/ansible'
alias ansible-playbook='/opt/kubespray-venv/bin/ansible-playbook'
alias ansible-inventory='/opt/kubespray-venv/bin/ansible-inventory'
```

## Kiểm tra môi trường

### Test script
Sử dụng script test để kiểm tra môi trường:

```bash
./scripts/test-python-env.sh
```

### Kiểm tra thủ công
```bash
# Kiểm tra virtual environment
ls -la /opt/kubespray-venv/

# Kiểm tra ansible
ansible --version

# Kiểm tra pip trong virtual environment
source /opt/kubespray-venv/bin/activate
pip list
deactivate
```

## Tích hợp vào quy trình cài đặt

### Pre-installation
Script `pre-install.sh` đã được cập nhật để tự động chạy fix Python environment.

### Kubespray installation
Script `install-kubespray.sh` đã được cập nhật để sử dụng virtual environment khi cần thiết.

### Main installation
Script `install.sh` tích hợp fix Python environment vào quy trình cài đặt.

## Kết quả

### Trước khi fix:
- ❌ Không thể cài đặt packages với pip3
- ❌ Lỗi externally-managed-environment
- ❌ Không thể cài đặt Ansible

### Sau khi fix:
- ✅ Virtual environment tại `/opt/kubespray-venv`
- ✅ Ansible đã được cài đặt và hoạt động
- ✅ Alias tự động cho ansible commands
- ✅ Tương thích với Ubuntu 24.04+

## Sử dụng

### Activate virtual environment:
```bash
source /opt/kubespray-venv/bin/activate
```

### Deactivate virtual environment:
```bash
deactivate
```

### Sử dụng ansible (với alias):
```bash
ansible --version
ansible-playbook -i inventory/hosts.yml playbook.yml
```

## Troubleshooting

### Nếu virtual environment bị lỗi:
```bash
# Xóa và tạo lại
sudo rm -rf /opt/kubespray-venv
./scripts/fix-python-env.sh
```

### Nếu alias không hoạt động:
```bash
# Reload bashrc
source ~/.bashrc

# Hoặc thêm alias thủ công
echo "alias ansible='/opt/kubespray-venv/bin/ansible'" >> ~/.bashrc
```

### Nếu cần cài đặt packages khác:
```bash
source /opt/kubespray-venv/bin/activate
pip install package-name
deactivate
```

## Kết luận
Vấn đề Python externally-managed-environment đã được giải quyết hoàn toàn với:
- Virtual environment tự động
- Script fix tích hợp
- Alias tiện lợi
- Tương thích đầy đủ với Ubuntu 24.04+

Project hiện tại đã sẵn sàng để cài đặt Kubernetes cluster trên Ubuntu 24.04+. 