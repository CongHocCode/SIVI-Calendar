// lib/widgets/hop_thoai_them.dart

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart'; //Cho đồng hồ cuộn
import 'package:intl/intl.dart'; //Để format ngày
import '../models/mon_hoc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HopThoaiThemMon extends StatefulWidget {
  final MonHoc? monHocHienTai; //Có biến này để khi sửa có thể lấy thông tin cũ ra sửa
  const HopThoaiThemMon({super.key, this.monHocHienTai});

  @override
  State<HopThoaiThemMon> createState() => _HopThoaiThemMonState();
}

class _HopThoaiThemMonState extends State<HopThoaiThemMon> {
  // Controller
  final _tenController = TextEditingController();
  final _phongController = TextEditingController();
  final _gvController = TextEditingController();
  final _gioController = TextEditingController();
  final _ngayController = TextEditingController();
  final _ghiChuController = TextEditingController(); // [MỚI] Controller cho ghi chú

  DateTime _selectedDate = DateTime.now(); // Biến lưu ngày thực sự
  
  // [MỚI] Biến chọn Loại sự kiện (0: Học, 1: Cá nhân)
  int _loaiSuKien = 0; 

  // Cấu hình nhắc nhở
  int _nhacTruoc = 15;
  final Map<int, String> _tuyChonNhac = {
    0: "Không nhắc",
    1: "Trước 1 phút (Test)", 
    15: "Trước 15 phút",
    30: "Trước 30 phút",
    60: "Trước 1 tiếng",
    1440: "Trước 1 ngày"
  };
  
  // [MỚI] Biến chọn Màu sắc
  int _mauDaChon = 0xFF2196F3; // Mặc định xanh
  final List<int> _bangMau = [
    0xFF2196F3, // Blue
    0xFFF44336, // Red
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF009688, // Teal
  ];

  // Cấu hình lặp lại
  bool _coLapLai = false;
  int _soLuongLap = 15; // Số lượng (ngày hoặc tuần)
  int _loaiLap = 7; // 1: Lặp theo Ngày, 7: Lặp theo Tuần

  @override
  void initState() {
    super.initState();
    // Load dữ liệu cũ nếu là Sửa
    if (widget.monHocHienTai != null) {
      final mon = widget.monHocHienTai!;
      _tenController.text = mon.tenMon;
      _phongController.text = mon.phongHoc;
      _gvController.text = mon.giangVien;
      _gioController.text = mon.thoiGian;
      _selectedDate = mon.ngayHoc;
      _nhacTruoc = mon.nhacTruoc;
      // [MỚI] Load thêm các trường mới
      _ghiChuController.text = mon.ghiChu;
      _loaiSuKien = mon.loaiSuKien;
      _mauDaChon = mon.mauSac;
    }
    // Cập nhật text hiển thị ngày
    _ngayController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  //Dạng như hàm hủy
  @override
  void dispose() {
    _tenController.dispose();
    _phongController.dispose();
    _gvController.dispose();
    _gioController.dispose();
    _ngayController.dispose();
    _ghiChuController.dispose(); // [MỚI]
    super.dispose();
  }

  // --- HÀM CHỌN GIỜ (NumberPicker) ---
  Future<void> _chonGio() async {
    int gio = TimeOfDay.now().hour;
    int phut = TimeOfDay.now().minute;

    //Lấy giờ cũ ra nếu có
    if (_gioController.text.isNotEmpty) {
      try {
        var parts = _gioController.text.split(':');
        gio = int.parse(parts[0]);
        phut = int.parse(parts[1]);
      } catch (_) {}
    }
                    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Chọn giờ học", textAlign: TextAlign.center),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumberPicker(
                value: gio, minValue: 0, maxValue: 23, infiniteLoop: true,
                onChanged: (val) => setStateDialog(() => gio = val),
              ),
              const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              NumberPicker(
                value: phut, minValue: 0, maxValue: 59, infiniteLoop: true,
                textMapper: (s) => s.padLeft(2, '0'), // Fix hiển thị 00
                onChanged: (val) => setStateDialog(() => phut = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                // Fix lỗi hiển thị 7:5 -> 7:05
                _gioController.text = "$gio:${phut.toString().padLeft(2, '0')}";
                Navigator.pop(context);
              },
              child: const Text("Xong"),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM CHỌN NGÀY ---
  Future<void> _chonNgay() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _ngayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // --- LOGIC KIỂM TRA QUYỀN ---
  Future<bool> _checkPermission() async {
    if (!Platform.isAndroid) return true;
    
    var status = await Permission.scheduleExactAlarm.status; //Kiểm tra trạng thái quyền được báo theo lịch
    if (status.isDenied) { //Quyền bị từ chối thì hiện thông báo lên và mở giao diện xin quyền
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng cấp quyền để nhắc lịch!"), backgroundColor: Colors.orange),
        );
      }
      await Permission.scheduleExactAlarm.request();
      // Check lại lần nữa
      status = await Permission.scheduleExactAlarm.status; //Xem lại status
    }
    
    //return status.isGranted; //Dòng này để chỉnh nếu như muốn không có quyền thì không được lưu lịch
    return true;
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.monHocHienTai != null; //Nếu monHocHienTai tồn tại tức là đang update sự kiện

    return AlertDialog(
      title: Text(isEditing ? "Cập nhật" : "Thêm mới"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- [MỚI] CHỌN LOẠI SỰ KIỆN ---
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _loaiSuKien = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _loaiSuKien == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _loaiSuKien == 0 ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                        ),
                        child: const Center(child: Text("📚 Lịch Học", style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _loaiSuKien = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _loaiSuKien == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _loaiSuKien == 1 ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                        ),
                        child: const Center(child: Text("☕ Cá Nhân", style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ---------------------------

            TextField(
              controller: _tenController, 
              decoration: InputDecoration(
                labelText: _loaiSuKien == 0 ? "Tên môn" : "Tên sự kiện", // Đổi tên linh hoạt
                hintText: _loaiSuKien == 0 ? "VD: Toán" : "VD: Đi chơi",
              )
            ),

            TextField(
              controller: _phongController, 
              decoration: InputDecoration(
                labelText: _loaiSuKien == 0 ? "Phòng" : "Địa điểm", // Đổi tên linh hoạt
                hintText: _loaiSuKien == 0 ? "VD: B101" : "VD: Quán Cafe",
              )
            ),

            // Chỉ hiện Giảng Viên nếu là Lịch Học
            if (_loaiSuKien == 0)
              TextField(
                controller: _gvController, 
                decoration: const InputDecoration(labelText: "Giảng viên", hintText: "VD: Thầy A")
              ),

            // [MỚI] Ô Ghi chú nằm ngay đây
            TextField(
              controller: _ghiChuController, 
              decoration: const InputDecoration(labelText: "Ghi chú", hintText: "VD: Mang máy tính"),
              maxLines: 2,
            ),

            // Hàng chọn Ngày - Giờ
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ngayController, readOnly: true, onTap: _chonNgay,
                    decoration: const InputDecoration(labelText: "Ngày", prefixIcon: Icon(Icons.calendar_today)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _gioController, readOnly: true, onTap: _chonGio,
                    decoration: const InputDecoration(labelText: "Giờ", prefixIcon: Icon(Icons.access_time)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Dropdown chọn thời gian nhắc //TODO: hỏi lại cái val
            DropdownButtonFormField<int>(
              value: _nhacTruoc,
              isExpanded: true, // Quan trọng: Để chữ tự co giãn
              decoration: const InputDecoration(
                labelText: "Thông báo nhắc nhở",
                prefixIcon: Icon(Icons.notifications_active, color: Colors.amber),
                border: OutlineInputBorder(),
                // GIẢM PADDING XUỐNG
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              items: _tuyChonNhac.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  // Cho chữ nhỏ lại xíu (14) và cắt bớt nếu quá dài
                  style: const TextStyle(fontSize: 14), 
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (val) => setState(() => _nhacTruoc = val!),
            ),

            const SizedBox(height: 15),
            
            // --- [MỚI] CHỌN MÀU SẮC ---
            const Align(alignment: Alignment.centerLeft, child: Text("Màu sắc:", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _bangMau.map((mau) {
                bool isSelected = _mauDaChon == mau;
                return GestureDetector(
                  onTap: () => setState(() => _mauDaChon = mau),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Color(mau),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            // --------------------------

            // --- PHẦN LẶP LẠI (Chỉ hiện khi Thêm Mới) --- TODO: Check lại cái active gì đó
            if (!isEditing) ...[
              const Divider(),
              SwitchListTile(
                title: const Text("Lặp lại?"),
                value: _coLapLai,
                contentPadding: EdgeInsets.zero,
                activeTrackColor: Colors.blueAccent, 
                onChanged: (val) => setState(() => _coLapLai = val),
              ),

              if (_coLapLai)
                Column(
                  children: [
                    // Chọn loại lặp: Ngày hay Tuần
                    Row(
                      children: [
                        const Text("Lặp mỗi: "),
                        const SizedBox(width: 10),
                        DropdownButton<int>( //menu lựa chọn lặp lại theo ngày và tuần
                          value: _loaiLap,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("Ngày")),
                            DropdownMenuItem(value: 7, child: Text("Tuần")),
                          ], 
                          onChanged: (val) => setState(() => _loaiLap = val!),
                        ),
                      ],
                    ),
                    // Chọn số lượng (lặp bao nhiêu ngày, lặp bao nhiêu tuần)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() { if(_soLuongLap > 1) _soLuongLap--; }),
                        ),
                        Text("$_soLuongLap lần", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => setState(() { if(_soLuongLap < 50) _soLuongLap++; }),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),


      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: () async {
            if(_tenController.text.trim().isEmpty) return;
            
            // KIỂM TRA QUYỀN ĐỂ HẸN LỊCH THÔNG BÁO
            if (_nhacTruoc > 0 && Platform.isAndroid) { // Chỉ check nếu có nhắc
              var status = await Permission.scheduleExactAlarm.status;
              if (status.isDenied) {
                //Hiện thông báo nhắc nhở
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bạn cần cấp quyền 'Báo thức' để App nhắc lịch nhé!"),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                await Permission.scheduleExactAlarm.request(); //Mở trang cài đặt\
                status = await Permission.scheduleExactAlarm.status;
                
                // Nếu sau khi mở cài đặt mà vẫn chưa có quyền thì dừng lại
                if (status.isDenied) return;
              }
            }

            final isEditing = widget.monHocHienTai != null;
            
            // TRƯỜNG HỢP 1: ĐANG SỬA (Trả về 1 Object)
            if (isEditing) {
              final monDaSua = MonHoc(
                id: widget.monHocHienTai!.id, // Giữ nguyên ID cũ
                tenMon: _tenController.text,
                phongHoc: _phongController.text,
                thoiGian: _gioController.text,
                giangVien: _gvController.text,
                ngayHoc: _selectedDate, // Ngày có thể sửa
                ghiChu: _ghiChuController.text, //Lấy từ controller thay vì ghiChu cũ
                nhacTruoc: _nhacTruoc, // Lấy từ biến mới chọn
                loaiSuKien: _loaiSuKien, 
                mauSac: _mauDaChon,
              );

              if (context.mounted) {
                Navigator.pop(context, monDaSua); 
              }
            } 
            
            // TRƯỜNG HỢP 2: THÊM MỚI (Trả về List)
            else {
              List<MonHoc> ketQua = [];
              int soLanLoop = _coLapLai ? _soLuongLap : 1; //Có lặp lại thì soLanLoop là số lượng lặp lại được chọn ở trên
              int buocNhayNgay = _coLapLai ? _loaiLap : 0; // Bước nhảy dựa trên loại lặp (theo tuần thì nhảy 7, theo ngày thì nhảy 1)

              //Thêm từng lịch là một object vào list để trả về
              for (var i = 0; i < soLanLoop; i++) {
                DateTime ngayMoi = _selectedDate.add(Duration(days: buocNhayNgay * i));
                
                ketQua.add(MonHoc(
                  tenMon: _tenController.text,
                  phongHoc: _phongController.text,
                  thoiGian: _gioController.text,
                  giangVien: _gvController.text,
                  ngayHoc: ngayMoi,
                  ghiChu: _ghiChuController.text, // Lấy từ controller
                  nhacTruoc: _nhacTruoc,
                  loaiSuKien: _loaiSuKien, 
                  mauSac: _mauDaChon,
                ));
              }

              if (context.mounted) {
                Navigator.pop(context, ketQua);
              }
            }
          },
          child: Text(widget.monHocHienTai != null ? "Cập nhật" : "Lưu"), 
        )
      ],
    );
  }
}