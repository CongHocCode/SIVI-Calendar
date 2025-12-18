import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart'; //Cho đồng hồ cuộn
import 'package:intl/intl.dart'; //Để format ngày
import '../models/mon_hoc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HopThoaiThemMon extends StatefulWidget {
  final MonHoc? monHocHienTai;
  const HopThoaiThemMon({super.key, this.monHocHienTai});

  @override
  State<HopThoaiThemMon> createState() => _HopThoaiThemMonState();
}

class _HopThoaiThemMonState extends State<HopThoaiThemMon> {
  //Controller
  final _tenController = TextEditingController();
  final _phongController = TextEditingController();
  final _gvController = TextEditingController();
  final _gioController = TextEditingController();
  final _ngayController = TextEditingController();

  DateTime _selectedDate = DateTime.now(); // Biến lưu ngày thực sự

  //Khởi đầu với dữ liệu cũ để khi người dùng sửa không bị trống trơn
  @override
  void initState() {
    super.initState();

    if (widget.monHocHienTai != null) {
      final mon = widget.monHocHienTai!;
      _tenController.text = mon.tenMon;
      _phongController.text = mon.phongHoc;
      _gvController.text = mon.giangVien;
      _gioController.text = mon.thoiGian;
      _selectedDate = mon.ngayHoc; //Lấy ngày cũ
      _ngayController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    } else {
      //Nếu thêm mới thì mặc định là ngày hôm nay
      _ngayController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    }
  }

  //Hàm chọn giờ
  Future<void> _chonGio() async {
    int gioChon = TimeOfDay.now().hour;
    int phutChon = TimeOfDay.now().minute;

    //Đọc giờ cũ để tiếp tục từ đó
    if (_gioController.text.isNotEmpty) {
      try {
        var parts = _gioController.text.split(':');
        gioChon = int.parse(parts[0]);
        phutChon = int.parse(parts[1]);
      } catch (e) {
        //Nếu lỗi thì dùng giờ hiện tại để bắt đầu
      }
    }
                    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        //StatefulBuilder: Để nhảy số khi cuộn
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Chọn giờ học", textAlign: TextAlign.center),

              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Cột giờ
                  NumberPicker(
                    value: gioChon,
                    minValue: 0,
                    maxValue: 23,
                    infiniteLoop: true,
                    itemWidth: 80,

                    textStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.blue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),

                    //Để có 2 cái thanh chỗ số đang được chọn
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blueAccent),
                        bottom: BorderSide(color: Colors.blueAccent),
                      ),
                    ),

                    //Gán số đang được chọn vào biến gioChon
                    onChanged: (value) {
                      setStateDialog(() => gioChon = value);
                    },
                  ),


                  const Text(
                    ":",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),


                  //Cột phút
                  NumberPicker(
                    value: phutChon,
                    minValue: 0,
                    maxValue: 59,
                    infiniteLoop: true,
                    itemWidth: 80,

                    //Hiển thị 00 thay vì 0 bằng customMapper
                    textMapper: (numberText) => numberText.padLeft(2, '0'),

                    textStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.blue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),

                    //Hiển thị 2 thanh màu ở số đang được chọn
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blueAccent),
                        bottom: BorderSide(color: Colors.blueAccent),
                      ),
                    ),

                    //Gán số đang được chọn vào biến
                    onChanged: (value) {
                      setStateDialog(() => phutChon = value);
                    },
                  ),
                ],
              ),


              //Các nút thao tác chọn giờ
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),

                ElevatedButton(
                  onPressed: () {
                    String gio = gioChon.toString();
                    String phut = phutChon.toString().padLeft(2, '0');
                    _gioController.text = "$gio:$phut";
                    Navigator.pop(context);
                  },
                  child: const Text("Xong"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  //Hàm chọn ngày (DatePicker)
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

  @override
  void dispose() {
    //Hủy controller
    _tenController.dispose();
    _phongController.dispose();
    _gioController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //Giao diện thêm môn học
      title: Text(widget.monHocHienTai != null ? "Cập nhật môn học" : "Thêm môn học mới"),

      //SigleChildScrollView: Nó biến nội dung bên trong thành một vùng cuộn được. Nếu không đủ chỗ, người dùng có thể vuốt ngón tay để xem phần bị che khuất.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tenController,
              decoration: const InputDecoration(labelText: "Tên môn", hintText: "VD: Toán"),
            ),

            TextField(
              controller: _phongController,
              decoration: const InputDecoration(labelText: "Phòng", hintText: "VD: B101"),
            ),

            TextField(
              controller: _gvController,
              decoration: const InputDecoration(labelText: "Giảng viên", hintText: "VD: Nguyen Van A"),
            ),

            TextField(
              controller: _ngayController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Ngày học", prefixIcon: Icon(Icons.calendar_today)),
              onTap: _chonNgay,
            ),

            TextField(
              controller: _gioController,
              readOnly: true, //Ngăn không bàn phím lên khi nhấn vào
              decoration: const InputDecoration(
                labelText: "Giờ học",
                prefixIcon: Icon(Icons.access_time), 
              ),
              onTap: _chonGio,
            ),
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
            if (Platform.isAndroid) {
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

              }

            }

            final isEditing = widget.monHocHienTai != null;
            //Tạo object MonHoc từ dữ liệu nhập
            final monMoi = MonHoc(
              tenMon: _tenController.text,
              phongHoc: _phongController.text,
              thoiGian: _gioController.text,
              giangVien: _gvController.text,
              ngayHoc: _selectedDate,
              //Logic giữ ghi chú
              ghiChu: isEditing ? widget.monHocHienTai!.ghiChu: "",
            );

            //Trả về dữ liệu cho màn hình chính
            Navigator.pop(context, monMoi);
          },
          child: Text(widget.monHocHienTai != null ? "Cập nhật" : "Lưu"), 
        )
      ],
    );
  }
}
