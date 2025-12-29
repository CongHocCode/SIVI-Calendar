# 🐧 SIVI Calendar - Trợ lý Lịch học Sinh viên 

Ứng dụng quản lý thời khóa biểu thông minh, tích hợp đồng bộ dữ liệu từ cổng thông tin đào tạo (Web Scraping) và nhắc nhở lịch học tự động. (Còn bug chưa fix 🐧)

## ✨ Tính năng nổi bật

- **📅 Quản lý Lịch học & Cá nhân:** Xem lịch theo tuần/ngày, phân loại bằng màu sắc và icon trực quan.
- **🤖 Auto Bot Đồng bộ:** Tự động đăng nhập vào web trường, vượt qua các thao tác phức tạp để "cào" lịch học về máy chỉ trong 1 cú click.
- **🔔 Nhắc nhở Thông minh:**
  - Hẹn giờ nhắc trước (15p, 30p, 1 ngày...).
  - Hỗ trợ đánh thức màn hình (Wake Screen) như báo thức.
  - **Anti-Kill:** Tích hợp hướng dẫn cấp quyền chạy nền cho các dòng máy "khó tính" như OPPO, Xiaomi.
- **💾 Offline First:** Lưu trữ dữ liệu vĩnh viễn bằng SQLite (sqflite). Tắt mạng vẫn xem được lịch.
- **📦 Sao lưu & Khôi phục:** Xuất dữ liệu ra file JSON để chuyển sang máy khác.

## 🛠️ Công nghệ sử dụng

- **Framework:** Flutter
- **Database:** SQLite (`sqflite`)
- **State Management:** Vanilla (setState + Service Pattern)
- **Web Scraping:** `flutter_inappwebview`, `html`
- **Notifications:** `flutter_local_notifications`, `android_intent_plus`

## 📸 Hình ảnh minh họa

| Lịch Tuần | Chi tiết Môn | Auto Bot |
|:---------:|:------------:|:--------:|
| ... | ... | ... |
(Chưa chụp 🐧)

## 🚀 Cài đặt & Sử dụng

1. Tải file APK mới nhất trong phần [Releases](Link_tới_repo_của_bạn/releases).
2. Cài đặt vào điện thoại Android.
3. Mở App -> Menu 3 chấm -> **Đồng bộ từ Web**.
4. Đăng nhập và chọn số tuần muốn lấy dữ liệu.

## ⚠️ Lưu ý cho máy OPPO/Xiaomi

Nếu không nhận được thông báo, vui lòng vào **Menu > Sửa lỗi không báo** và cấp quyền **Tự khởi chạy (Auto-Start)** cho ứng dụng.

---
Developed with ❤️ by [CongHocCode]
