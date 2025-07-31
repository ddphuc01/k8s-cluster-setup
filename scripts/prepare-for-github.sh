#!/bin/bash

# Prepare for GitHub Script
# Chuẩn bị project để đưa lên GitHub

set -e

echo "=========================================="
echo "  Prepare Project for GitHub"
echo "=========================================="
echo ""

# Kiểm tra git
if ! command -v git &> /dev/null; then
    echo "❌ Git không được tìm thấy. Vui lòng cài đặt git trước."
    exit 1
fi

# Kiểm tra xem đã có git repository chưa
if [ ! -d ".git" ]; then
    echo "[INFO] Khởi tạo Git repository..."
    git init
    echo "[SUCCESS] Git repository đã được khởi tạo"
else
    echo "[INFO] Git repository đã tồn tại"
fi

# Xóa các file không cần thiết cho GitHub
echo "[INFO] Dọn dẹp files không cần thiết..."

# Xóa kubespray directory nếu có
if [ -d "kubespray" ]; then
    echo "  - Xóa kubespray directory..."
    rm -rf kubespray
fi

# Xóa các file logs
echo "  - Xóa log files..."
find . -name "*.log" -type f -delete 2>/dev/null || true

# Xóa các file tạm
echo "  - Xóa temporary files..."
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "*.temp" -type f -delete 2>/dev/null || true

# Xóa SSH keys (nếu có)
echo "  - Kiểm tra SSH keys..."
if [ -f "~/.ssh/id_rsa" ]; then
    echo "    ⚠️  SSH private key được tìm thấy. Đảm bảo nó đã được thêm vào .gitignore"
fi

# Tạo file .gitattributes
echo "[INFO] Tạo .gitattributes..."
cat > .gitattributes << EOF
# Auto detect text files and perform LF normalization
* text=auto

# Scripts
*.sh text eol=lf
*.py text eol=lf

# Documentation
*.md text eol=lf
*.txt text eol=lf

# Configuration files
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf
*.conf text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
*.tar.gz binary
*.tgz binary
EOF

echo "[SUCCESS] .gitattributes đã được tạo"

# Kiểm tra .gitignore
if [ ! -f ".gitignore" ]; then
    echo "❌ .gitignore không tồn tại. Vui lòng tạo file .gitignore trước."
    exit 1
fi

echo "[SUCCESS] .gitignore đã tồn tại"

# Tạo file CHANGELOG.md
echo "[INFO] Tạo CHANGELOG.md..."
cat > CHANGELOG.md << EOF
# Changelog

Tất cả các thay đổi quan trọng trong project này sẽ được ghi lại trong file này.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
và project này tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Kubernetes cluster setup với Calico networking
- Rancher management platform integration
- Comprehensive automation scripts
- Python environment fix cho Ubuntu 24.04+
- MetalLB load balancer support
- NGINX Ingress Controller
- Detailed documentation và troubleshooting guides

### Changed
- Initial release

### Fixed
- Python externally-managed-environment issue
- SSH key authentication setup
- Ansible inventory configuration

## [1.0.0] - 2025-07-30

### Added
- Initial release với Kubernetes v1.29.15
- Calico CNI v3.26.4
- Kubespray automation
- Rancher v2.8.x integration
- Ubuntu 24.04+ support
EOF

echo "[SUCCESS] CHANGELOG.md đã được tạo"

# Tạo file CONTRIBUTING.md
echo "[INFO] Tạo CONTRIBUTING.md..."
cat > CONTRIBUTING.md << EOF
# Contributing

Cảm ơn bạn đã quan tâm đến việc đóng góp cho project này!

## Cách đóng góp

### Báo cáo lỗi

1. Kiểm tra xem lỗi đã được báo cáo chưa trong [Issues](https://github.com/yourusername/k8s-cluster-setup/issues)
2. Tạo issue mới với mô tả chi tiết về lỗi
3. Bao gồm thông tin về:
   - Hệ điều hành và phiên bản
   - Kubernetes version
   - Các bước để tái tạo lỗi
   - Log files (nếu có)

### Đề xuất tính năng

1. Kiểm tra xem tính năng đã được đề xuất chưa
2. Tạo issue mới với mô tả chi tiết về tính năng
3. Giải thích lý do tại sao tính năng này hữu ích

### Đóng góp code

1. Fork project này
2. Tạo feature branch: \`git checkout -b feature/AmazingFeature\`
3. Commit changes: \`git commit -m 'Add some AmazingFeature'\`
4. Push to branch: \`git push origin feature/AmazingFeature\`
5. Mở Pull Request

### Development Setup

\`\`\`bash
# Clone repository
git clone https://github.com/yourusername/k8s-cluster-setup.git
cd k8s-cluster-setup

# Create development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
\`\`\`

### Code Style

- Sử dụng consistent indentation (2 spaces cho YAML, 4 spaces cho Python)
- Thêm comments cho complex logic
- Đảm bảo scripts có proper error handling
- Test scripts trước khi commit

### Testing

- Test trên Ubuntu 20.04+ và CentOS 8+
- Kiểm tra compatibility với different Kubernetes versions
- Verify network connectivity và security policies

## Code of Conduct

Project này tuân thủ [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## License

Bằng cách đóng góp, bạn đồng ý rằng đóng góp của bạn sẽ được cấp phép dưới MIT License.
EOF

echo "[SUCCESS] CONTRIBUTING.md đã được tạo"

# Tạo file CODE_OF_CONDUCT.md
echo "[INFO] Tạo CODE_OF_CONDUCT.md..."
cat > CODE_OF_CONDUCT.md << EOF
# Code of Conduct

## Our Pledge

Chúng tôi cam kết tạo ra một môi trường mở và thân thiện cho tất cả mọi người, bất kể tuổi tác, kích thước cơ thể, khuyết tật, dân tộc, đặc điểm giới tính, bản sắc và biểu hiện giới tính, mức độ kinh nghiệm, giáo dục, tình trạng kinh tế xã hội, quốc tịch, ngoại hình cá nhân, chủng tộc, tôn giáo, hoặc định hướng tình dục và bản sắc.

## Our Standards

Ví dụ về hành vi góp phần tạo ra môi trường tích cực:

* Sử dụng ngôn ngữ thân thiện và bao gồm
* Tôn trọng quan điểm và trải nghiệm khác nhau
* Chấp nhận phản hồi một cách duyên dáng
* Tập trung vào những gì tốt nhất cho cộng đồng
* Thể hiện sự đồng cảm với các thành viên cộng đồng khác

Ví dụ về hành vi không thể chấp nhận:

* Sử dụng ngôn ngữ hoặc hình ảnh tình dục và sự quấy rối tình dục không mong muốn
* Trolling, comments xúc phạm/khinh miệt, và tấn công cá nhân hoặc chính trị
* Quấy rối công khai hoặc riêng tư
* Xuất bản thông tin cá nhân của người khác, chẳng hạn như địa chỉ email vật lý hoặc điện tử, mà không có sự cho phép rõ ràng
* Hành vi khác có thể được coi là không phù hợp trong môi trường chuyên nghiệp

## Our Responsibilities

Người duy trì project có trách nhiệm làm rõ các tiêu chuẩn về hành vi có thể chấp nhận được và dự kiến sẽ thực hiện hành động khắc phục thích hợp và công bằng để đáp ứng với bất kỳ trường hợp hành vi không thể chấp nhận được.

## Scope

Code of Conduct này áp dụng trong tất cả các không gian project và cũng áp dụng khi một cá nhân đang đại diện cho project hoặc cộng đồng của nó trong không gian công cộng.

## Enforcement

Các trường hợp lạm dụng, quấy rối hoặc hành vi không thể chấp nhận được khác có thể được báo cáo bằng cách liên hệ với team project. Tất cả các khiếu nại sẽ được xem xét và điều tra và sẽ dẫn đến phản hồi được coi là cần thiết và phù hợp với hoàn cảnh.

## Attribution

Code of Conduct này được thích ứng từ [Contributor Covenant](https://www.contributor-covenant.org/), version 1.4, có sẵn tại https://www.contributor-covenant.org/version/1/4/code-of-conduct.html
EOF

echo "[SUCCESS] CODE_OF_CONDUCT.md đã được tạo"

# Kiểm tra trạng thái git
echo "[INFO] Kiểm tra trạng thái Git..."
git status

echo ""
echo "=========================================="
echo "  Project đã sẵn sàng cho GitHub!"
echo "=========================================="
echo ""
echo "📋 Các bước tiếp theo:"
echo ""
echo "1. Tạo repository trên GitHub:"
echo "   - Vào https://github.com/new"
echo "   - Đặt tên: k8s-cluster-setup"
echo "   - Chọn Public hoặc Private"
echo "   - Không tạo README (đã có sẵn)"
echo ""
echo "2. Push code lên GitHub:"
echo "   git add ."
echo "   git commit -m 'Initial commit: Kubernetes cluster setup with Calico and Rancher'"
echo "   git branch -M main"
echo "   git remote add origin https://github.com/yourusername/k8s-cluster-setup.git"
echo "   git push -u origin main"
echo ""
echo "3. Cập nhật README:"
echo "   - Thay đổi 'yourusername' thành username thực tế"
echo "   - Cập nhật email trong GITHUB_README.md"
echo ""
echo "4. Tạo GitHub Pages (tùy chọn):"
echo "   - Vào Settings > Pages"
echo "   - Chọn source: Deploy from a branch"
echo "   - Chọn branch: main, folder: /docs"
echo ""
echo "🎉 Project đã sẵn sàng để chia sẻ với cộng đồng!" 