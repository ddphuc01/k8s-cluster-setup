#!/bin/bash

# Kubernetes Cluster Installation Script
# Script chính để cài đặt Kubernetes cluster với Calico networking

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_system_requirements() {
    print_status "Kiểm tra yêu cầu hệ thống..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        print_error "Không thể xác định hệ điều hành"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        print_warning "Hệ điều hành được khuyến nghị: Ubuntu/Debian"
    fi
    
    # Check memory
    local mem_total=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [[ $mem_total -lt 2 ]]; then
        print_error "Cần ít nhất 2GB RAM. Hiện tại: ${mem_total}GB"
        exit 1
    fi
    
    # Check disk space
    local disk_free=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_free -lt 10 ]]; then
        print_error "Cần ít nhất 10GB disk space. Hiện tại: ${disk_free}GB"
        exit 1
    fi
    
    print_success "Hệ thống đáp ứng yêu cầu tối thiểu"
}

# Function to setup SSH keys
setup_ssh_keys() {
    print_status "Thiết lập SSH keys..."
    
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        print_status "Tạo SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "k8s-cluster-setup"
    fi
    
    # Copy key to worker node
    print_status "Copy SSH key đến worker node..."
    if ! ssh-copy-id -o StrictHostKeyChecking=no phuc@192.168.56.102; then
        print_warning "Không thể copy SSH key tự động. Vui lòng copy thủ công:"
        echo "ssh-copy-id phuc@192.168.56.102"
        read -p "Nhấn Enter sau khi đã copy SSH key..."
    fi
    
    print_success "SSH keys đã được thiết lập"
}

# Function to run pre-installation
run_pre_install() {
    print_status "Chạy pre-installation script..."
    
    if [[ ! -f scripts/pre-install.sh ]]; then
        print_error "Không tìm thấy pre-install.sh script"
        exit 1
    fi
    
    chmod +x scripts/pre-install.sh
    sudo ./scripts/pre-install.sh
    
    # Fix Python environment nếu cần
    if [[ -f scripts/fix-python-env.sh ]]; then
        print_status "Kiểm tra và fix Python environment..."
        chmod +x scripts/fix-python-env.sh
        ./scripts/fix-python-env.sh
    fi
    
    print_success "Pre-installation hoàn thành"
}

# Function to run kubespray installation
run_kubespray_install() {
    print_status "Bắt đầu cài đặt Kubernetes với Kubespray..."
    
    if [[ ! -f scripts/install-kubespray.sh ]]; then
        print_error "Không tìm thấy install-kubespray.sh script"
        exit 1
    fi
    
    chmod +x scripts/install-kubespray.sh
    ./scripts/install-kubespray.sh
    
    print_success "Kubespray installation hoàn thành"
}

# Function to run post-installation
run_post_install() {
    print_status "Chạy post-installation script..."
    
    if [[ ! -f scripts/post-install.sh ]]; then
        print_error "Không tìm thấy post-install.sh script"
        exit 1
    fi
    
    chmod +x scripts/post-install.sh
    ./scripts/post-install.sh
    
    print_success "Post-installation hoàn thành"
}

# Function to verify installation
verify_installation() {
    print_status "Kiểm tra cài đặt..."
    
    # Check if kubectl is available
    if ! command_exists kubectl; then
        print_error "kubectl không được tìm thấy"
        return 1
    fi
    
    # Check cluster status
    print_status "Kiểm tra cluster status..."
    kubectl cluster-info
    
    # Check nodes
    print_status "Kiểm tra nodes..."
    kubectl get nodes -o wide
    
    # Check pods
    print_status "Kiểm tra pods..."
    kubectl get pods -A
    
    # Check services
    print_status "Kiểm tra services..."
    kubectl get svc -A
    
    # Check calico
    print_status "Kiểm tra Calico..."
    kubectl get pods -n kube-system -l k8s-app=calico-node
    
    print_success "Cài đặt đã được xác minh thành công"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -s, --skip-pre      Skip pre-installation"
    echo "  -k, --skip-kubespray Skip kubespray installation"
    echo "  -p, --skip-post     Skip post-installation"
    echo "  -v, --verify-only   Only verify installation"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full installation"
    echo "  $0 -s               # Skip pre-installation"
    echo "  $0 -v               # Only verify"
}

# Main function
main() {
    echo "=========================================="
    echo "  Kubernetes Cluster Installation Script"
    echo "=========================================="
    echo ""
    
    # Parse command line arguments
    SKIP_PRE=false
    SKIP_KUBESPRAY=false
    SKIP_POST=false
    VERIFY_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--skip-pre)
                SKIP_PRE=true
                shift
                ;;
            -k|--skip-kubespray)
                SKIP_KUBESPRAY=true
                shift
                ;;
            -p|--skip-post)
                SKIP_POST=true
                shift
                ;;
            -v|--verify-only)
                VERIFY_ONLY=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "Script này không nên chạy với quyền root"
        exit 1
    fi
    
    # Check system requirements
    check_system_requirements
    
    if [[ "$VERIFY_ONLY" == true ]]; then
        verify_installation
        exit 0
    fi
    
    # Setup SSH keys
    setup_ssh_keys
    
    # Run installation steps
    if [[ "$SKIP_PRE" == false ]]; then
        run_pre_install
    else
        print_warning "Bỏ qua pre-installation"
    fi
    
    if [[ "$SKIP_KUBESPRAY" == false ]]; then
        run_kubespray_install
    else
        print_warning "Bỏ qua kubespray installation"
    fi
    
    if [[ "$SKIP_POST" == false ]]; then
        run_post_install
    else
        print_warning "Bỏ qua post-installation"
    fi
    
    # Verify installation
    verify_installation
    
    echo ""
    echo "=========================================="
    print_success "Cài đặt Kubernetes cluster hoàn thành!"
    echo "=========================================="
    echo ""
    echo "Thông tin cluster:"
    echo "- Master Node: 192.168.56.101"
    echo "- Worker Node: 192.168.56.102"
    echo "- Pod Network: 10.233.64.0/18"
    echo "- Service Network: 10.233.0.0/18"
    echo ""
    echo "Các lệnh hữu ích:"
    echo "- kubectl get nodes          # Xem danh sách nodes"
    echo "- kubectl get pods -A        # Xem tất cả pods"
    echo "- kubectl get svc -A         # Xem tất cả services"
    echo "- kubectl cluster-info       # Thông tin cluster"
    echo ""
    echo "Tài liệu:"
    echo "- docs/installation.md       # Hướng dẫn cài đặt"
    echo "- docs/configuration.md      # Cấu hình chi tiết"
    echo "- docs/troubleshooting.md    # Xử lý sự cố"
    echo ""
    print_success "Cluster đã sẵn sàng để sử dụng!"
}

# Run main function
main "$@" 