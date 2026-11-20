#!/usr/bin/env bash
# ==============================================================================
# Script: check-security-headers.sh
# Mục đích: Kiểm tra tất cả Security Headers bằng lệnh curl -I (theo yêu cầu đề bài)
# ==============================================================================

set -uo pipefail

HOST="secure.example.com"
URL="https://${HOST}/"

echo "================================================================================"
echo " KIỂM TRA HTTP SECURITY HEADERS BẰNG: curl -I ${URL}"
echo "================================================================================"
# Dùng -k để bỏ qua xác thực chứng chỉ trong môi trường test local/self-signed
curl -k -I -H "Host: ${HOST}" "https://127.0.0.1/" 2>/dev/null || \
curl -I -H "Host: ${HOST}" "http://127.0.0.1/" 2>/dev/null || true

echo ""
echo "================================================================================"
echo " LỌC 3 SECURITY HEADERS BẮT BUỘC THEO YÊU CẦU ĐỀ BÀI:"
echo "================================================================================"
RESPONSE=$(curl -k -I -H "Host: ${HOST}" "https://127.0.0.1/" 2>/dev/null || \
           curl -I -H "Host: ${HOST}" "http://127.0.0.1/" 2>/dev/null || echo "")

echo "${RESPONSE}" | grep -iE "X-Frame-Options|X-Content-Type-Options|Strict-Transport-Security" || \
echo "Chạy lệnh thủ công: curl -k -I https://${HOST}/"

echo ""
echo "================================================================================"
echo " DANH SÁCH ĐẦY ĐỦ SECURITY HEADERS CẦN XÁC NHẬN:"
echo "================================================================================"
echo "1. X-Frame-Options: SAMEORIGIN                 -> Chống Clickjacking"
echo "2. X-Content-Type-Options: nosniff              -> Chống MIME-Sniffing"
echo "3. Strict-Transport-Security: max-age=31536000; includeSubDomains -> Chống SSL Stripping (HSTS)"
echo "4. X-XSS-Protection: 1; mode=block             -> Bộ lọc XSS trình duyệt cũ"
echo "5. Referrer-Policy: strict-origin-when-cross-origin -> Kiểm soát Referrer"
echo "6. Content-Security-Policy: default-src 'self'  -> CSP chống XSS toàn diện"
