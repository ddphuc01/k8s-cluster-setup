#!/bin/bash

# Fix Python Environment Script
# Xử lý vấn đề externally-managed-environment trên Ubuntu 24.04+

set -e

echo "=== Fix Python Environment Script ==="
echo "Xử lý vấn đề externally-managed-environment..."

# Kiểm tra Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $PYTHON_VERSION"

# Kiểm tra xem có externally-managed-environment không
if pip3 install --dry-run ansible 2>&1 | grep -q "externally-managed"; then
    echo "Phát hiện externally-managed environment"
    
    # Cài đặt python3-venv nếu chưa có
    if ! dpkg -l | grep -q python3-venv; then
        echo "Cài đặt python3-venv..."
        sudo apt update
        sudo apt install -y python3-venv python3-full
    fi
    
    # Tạo virtual environment
    echo "Tạo virtual environment cho Kubespray..."
    if [ -d "/opt/kubespray-venv" ]; then
        echo "Virtual environment đã tồn tại tại /opt/kubespray-venv"
    else
        sudo python3 -m venv /opt/kubespray-venv
        echo "Virtual environment đã được tạo tại /opt/kubespray-venv"
    fi
    
    # Cấu hình permissions
    sudo chown -R $USER:$USER /opt/kubespray-venv
    
    # Activate virtual environment
    source /opt/kubespray-venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Cài đặt Ansible
    echo "Cài đặt Ansible trong virtual environment..."
    pip install ansible
    
    echo "=== Virtual Environment Setup Complete ==="
    echo "Virtual environment: /opt/kubespray-venv"
    echo "Để activate: source /opt/kubespray-venv/bin/activate"
    echo "Để deactivate: deactivate"
    
    # Tạo alias cho convenience
    echo "Tạo alias cho ansible..."
    echo "alias ansible='/opt/kubespray-venv/bin/ansible'" >> ~/.bashrc
    echo "alias ansible-playbook='/opt/kubespray-venv/bin/ansible-playbook'" >> ~/.bashrc
    echo "alias ansible-inventory='/opt/kubespray-venv/bin/ansible-inventory'" >> ~/.bashrc
    
    echo "Alias đã được thêm vào ~/.bashrc"
    echo "Chạy 'source ~/.bashrc' để áp dụng alias"
    
else
    echo "Không phát hiện externally-managed environment"
    echo "Có thể cài đặt packages trực tiếp với pip3"
fi

echo "=== Python Environment Fix Complete ===" 