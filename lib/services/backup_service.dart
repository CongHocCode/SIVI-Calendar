import 'dart:convert'; //Đổi file sang json các kiểu
import 'dart:io'; //Làm việc với nền tảng
import 'package:file_picker/file_picker.dart'; //Mở hộp thoại chọn file trên máy, upload file,...
import 'package:flutter/material.dart'; //UI
import 'package:intl/intl.dart'; //Format ngày giờ số
import 'package:path_provider/path_provider.dart'; //Lấy đường dẫn thư mục hệ thống
import 'package:share_plus/share_plus.dart'; //Chia sẻ nội dung ra ngoài app
import '../models/mon_hoc.dart'; //Có cái này để dùng toJson với fromJson các kiểu
import 'danh_sach_service.dart'; //Dùng các dịch vụ liên quan tới danh sách lịch

//TODO: Hoàn thiện phần backup vào file json