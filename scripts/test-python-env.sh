#!/bin/bash

# Test Python Environment Script
# Kiểm tra Python environment và dependencies

set -e

echo "=== Test Python Environment ==="

# Kiểm tra Python version
echo "1. Python version:"
python3 --version

# Kiểm tra pip version
echo "2. Pip version:"
pip3 --version

# Kiểm tra externally-managed environment
echo "3. Kiểm tra externally-managed environment:"
if pip3 install --dry-run ansible 2>&1 | grep -q "externally-managed"; then
    echo "   ✓ Phát hiện externally-managed environment"
    echo "   → Cần sử dụng virtual environment"
else
    echo "   ✓ Không có externally-managed environment"
    echo "   → Có thể cài đặt packages trực tiếp"
fi

# Kiểm tra virtual environment
echo "4. Kiểm tra virtual environment:"
if [ -d "/opt/kubespray-venv" ]; then
    echo "   ✓ Virtual environment tồn tại tại /opt/kubespray-venv"
    
    # Test activate virtual environment
    source /opt/kubespray-venv/bin/activate
    echo "   ✓ Virtual environment activated"
    
    # Kiểm tra ansible trong virtual environment
    if command -v ansible >/dev/null 2>&1; then
        echo "   ✓ Ansible đã được cài đặt"
        ansible --version | head -1
    else
        echo "   ✗ Ansible chưa được cài đặt"
    fi
    
    deactivate
else
    echo "   ✗ Virtual environment không tồn tại"
fi

# Kiểm tra python3-venv package
echo "5. Kiểm tra python3-venv:"
if dpkg -l | grep -q python3-venv; then
    echo "   ✓ python3-venv đã được cài đặt"
else
    echo "   ✗ python3-venv chưa được cài đặt"
fi

# Kiểm tra python3-full package
echo "6. Kiểm tra python3-full:"
if dpkg -l | grep -q python3-full; then
    echo "   ✓ python3-full đã được cài đặt"
else
    echo "   ✗ python3-full chưa được cài đặt"
fi

echo ""
echo "=== Test Complete ==="

# Đưa ra khuyến nghị
echo ""
echo "Khuyến nghị:"
if pip3 --version 2>&1 | grep -q "externally-managed"; then
    if [ -d "/opt/kubespray-venv" ]; then
        echo "✓ Môi trường đã sẵn sàng cho Kubespray"
        echo "  Sử dụng: source /opt/kubespray-venv/bin/activate"
    else
        echo "⚠ Cần chạy: ./scripts/fix-python-env.sh"
    fi
else
    echo "✓ Có thể cài đặt packages trực tiếp với pip3"
fi 