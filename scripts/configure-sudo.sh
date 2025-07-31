#!/bin/bash

# Configure Sudo Password Script
# Cấu hình sudo password cho Ansible

set -e

echo "=== Configure Sudo Password Script ==="
echo "Cấu hình sudo password cho Ansible..."

# Kiểm tra xem có sudo password được cung cấp không
if [ -z "$SUDO_PASSWORD" ]; then
    echo "Nhập sudo password cho user phuc:"
    read -s SUDO_PASSWORD
    echo ""
fi

# Cập nhật inventory file với sudo password
echo "Cập nhật inventory file với sudo password..."

# Backup inventory file
cp inventory/hosts.yml inventory/hosts.yml.backup

# Cập nhật inventory file
cat > inventory/hosts.yml << EOF
all:
  hosts:
    master:
      ansible_host: 192.168.56.101
      ansible_user: phuc
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
      ansible_become: yes
      ansible_become_method: sudo
      ansible_become_user: root
      ansible_become_password: "${SUDO_PASSWORD}"
      ip: 192.168.56.101
      access_ip: 192.168.56.101
    worker:
      ansible_host: 192.168.56.102
      ansible_user: phuc
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
      ansible_become: yes
      ansible_become_method: sudo
      ansible_become_user: root
      ansible_become_password: "${SUDO_PASSWORD}"
      ip: 192.168.56.102
      access_ip: 192.168.56.102
  children:
    kube_control_plane:
      hosts:
        master:
    kube_node:
      hosts:
        master:
        worker:
    etcd:
      hosts:
        master:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
EOF

echo "Inventory file đã được cập nhật với sudo password"
echo "Backup file: inventory/hosts.yml.backup"

# Test Ansible connection
echo "Test Ansible connection..."
if [ -d "/opt/kubespray-venv" ]; then
    source /opt/kubespray-venv/bin/activate
    ansible all -m ping -i inventory/hosts.yml
    deactivate
else
    echo "Virtual environment không tồn tại, bỏ qua test Ansible"
fi

echo "=== Sudo Password Configuration Complete ===" 