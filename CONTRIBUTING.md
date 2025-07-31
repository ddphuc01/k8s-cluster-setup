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
2. Tạo feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add some AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Mở Pull Request

### Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/k8s-cluster-setup.git
cd k8s-cluster-setup

# Create development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

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
