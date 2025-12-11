// lib/screens/man_hinh_chi_tiet.dart

import 'package:flutter/material.dart';
import 'package:lich_hoc_sv/widgets/hop_thoai_them.dart';
import '../models/mon_hoc.dart'; // Import model MonHoc

class ManHinhChiTiet extends StatefulWidget {
  final MonHoc monHoc;
  final VoidCallback hamXoa; //TOASK
  final Function(MonHoc) hamSua;
  const ManHinhChiTiet({super.key, required this.monHoc, required this.hamXoa, required this.hamSua});

  @override
  State<ManHinhChiTiet> createState() => _ManHinhChiTietState(); //TOASK
}

class _ManHinhChiTietState extends State<ManHinhChiTiet> {
  //Controller quản lý ô ghi chú
  late TextEditingController _ghiChuController; //TOASK

  @override
  void initState() {
    super.initState();
    //Khoi tao voi noi dung ghi chu hien co
    _ghiChuController = TextEditingController(
      text: widget.monHoc.ghiChu,
    ); //TOASK
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.monHoc.tenMon),
        actions: [
          //Nút sửa
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () async {
              //Mở hộp thoại lên, truyền thông tin hiện tại vào để nó tự điền
              final monDaSua = await showDialog<MonHoc>(
                context: context,
                builder: (ctx) => HopThoaiThemMon(monHocHienTai: widget.monHoc), //Đưa môn học hiện tại cho hộp thoại thêm môn
              );

              if (monDaSua != null) {
                setState(() {
                  //Cập nhật giao diện
                  widget.monHoc.tenMon = monDaSua.tenMon;
                  widget.monHoc.phongHoc = monDaSua.phongHoc;
                  widget.monHoc.thoiGian = monDaSua.thoiGian;
                });

                //Báo về màn hình chính để lưu lại
                widget.hamSua(widget.monHoc);
              }
            },
          ),


          //Nút xóa
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              //Hiện bảng xác nhận xóa
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Xác nhận"),
                  content: const Text("Bạn có chắc muốn xóa môn này không?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy"),
                    ),


                    TextButton(
                      onPressed: () {
                        widget.hamXoa(); //Goi ham xoa
                        Navigator.pop(ctx); //Dong bang hoi
                        Navigator.pop(context); //Quay ve man hinh chinh TOASK
                      },
                      child: const Text(
                        "Xóa",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //Cho sát bên trái ?
          children: [
            //Thông tin giờ và phòng
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: Text("Giờ: ${widget.monHoc.thoiGian}"),
                subtitle: Text("Phòng: ${widget.monHoc.phongHoc}"),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Ghi chú:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            //O nhap ghi chu
            TextField(
              controller: _ghiChuController,
              maxLines: 5, //toi da 5 dong duoc hien thi
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "VD: Nhớ mang laptop,...",
              ),
              onChanged: (text) {
                widget.monHoc.ghiChu = text;
              },
            ),
          ],
        ),
      ),
    );
  }
}
