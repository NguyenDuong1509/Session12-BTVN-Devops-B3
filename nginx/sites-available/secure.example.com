# ==============================================================================
# FILE CẤU HÌNH HOÀN CHỈNH: secure.example.com (ĐÃ THÊM SECURITY HEADERS)
# Domain: secure.example.com
# Mục tiêu: Bảo vệ khỏi XSS, Clickjacking, MIME-Sniffing, SSL Stripping
# File Location: /etc/nginx/sites-available/secure.example.com
# ==============================================================================

# =============================================================================
# BLOCK 1: HTTPS SERVER (PORT 443) - SECURE ENDPOINT
# =============================================================================
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name secure.example.com;

    # --- CHỨNG CHỈ SSL ---
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # ==========================================================================
    # 3 SECURITY HEADERS BẮT BUỘC THEO YÊU CẦU ĐỀ BÀI
    # ==========================================================================

    # 1. Chống CLICKJACKING: Chỉ cho phép iframe từ cùng domain
    #    - DENY      : Cấm hoàn toàn nhúng iframe từ bất kỳ nguồn nào
    #    - SAMEORIGIN: Chỉ cho phép nhúng từ cùng scheme://domain:port
    add_header X-Frame-Options "SAMEORIGIN" always;

    # 2. Chống MIME-SNIFFING: Yêu cầu trình duyệt tuân thủ Content-Type
    #    Giá trị duy nhất hợp lệ là "nosniff"
    add_header X-Content-Type-Options "nosniff" always;

    # 3. HSTS (HTTP Strict Transport Security): Chống SSL Stripping Attack
    #    - max-age=31536000 : Trình duyệt nhớ chỉ dùng HTTPS trong 365 ngày
    #    - includeSubDomains: Áp dụng cho tất cả subdomain (api., admin., ...)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # ==========================================================================
    # SECURITY HEADERS BỔ SUNG (KHUYẾN NGHỊ OWASP CHO PRODUCTION)
    # ==========================================================================

    # 4. Bật bộ lọc XSS của trình duyệt cũ (IE/Chrome cũ)
    add_header X-XSS-Protection "1; mode=block" always;

    # 5. Kiểm soát Referrer Information khi điều hướng sang trang khác
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # 6. Content Security Policy (CSP): Giới hạn nguồn tải tài nguyên
    #    Chỉ cho phép script, style, image từ chính trang này (self)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self';" always;

    # 7. Ẩn phiên bản Nginx khỏi response header (giảm thông tin cho attacker)
    server_tokens off;

    # --- REVERSE PROXY ---
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
    }

    # Nhật ký truy cập
    access_log /var/log/nginx/secure.example.com.access.log;
    error_log  /var/log/nginx/secure.example.com.error.log warn;
}

# =============================================================================
# BLOCK 2: HTTP (PORT 80) -> Redirect sang HTTPS
# =============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name secure.example.com;

    # Chuyển hướng vĩnh viễn 301 sang HTTPS
    return 301 https://$host$request_uri;
}
