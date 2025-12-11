// lib/screens/man_hinh_lich.dart

import 'dart:convert'; //De dung jsonEncode jsonDecode TOASK
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; //De luu du lieu
import '../models/mon_hoc.dart'; // Import model
import 'man_hinh_chi_tiet.dart'; // Import man hinh chi tiet
import '../widgets/the_mon_hoc.dart';    // Import widget Card
import '../widgets/hop_thoai_them.dart'; // Import widget Dialog

//Man hinh chinh (Co the thay doi -> StatefulWidget)
class ManHinhLich extends StatefulWidget {
  const ManHinhLich({super.key});
  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  //List rỗng để lưu dữ liệu môn học
  final List<MonHoc> _danhSach = [];

  @override
  void initState() {
    super.initState();
    _docDuLieu();
  }

  // --- Hàm lưu / đọc dữ liệu từ file json ---
  Future<void> _luuDuLieu() async {
    final prefs = await SharedPreferences.getInstance();

    //List<MonHoc> -> List<Map> -> JSON
    //map((e) => e.toJson()) duyet tung phan tu va bien thanh map TOASK
    String dataJson = jsonEncode(_danhSach.map((e) => e.toJson()).toList());

    //Lưu chuỗi vào ổ cứng 'lich_hoc_key'
    await prefs.setString('lich_hoc_key', dataJson);
    print("Đã lưu dữ liệu: $dataJson");
  }


  Future<void> _docDuLieu() async {
    final prefs = await SharedPreferences.getInstance();

    //Đọc chuỗi JSON từ ổ cứng
    String? dataJson = prefs.getString('lich_hoc_key');

    if (dataJson != null) {
      //Decode JSON thanh List<dynamic> TOASK
      List<dynamic> jsonList = jsonDecode(dataJson);

      //Bien doi tung phan tu JSON tro lai thanh Object MonHoc
      setState(() {
        _danhSach.clear(); //Xoa du lieu mau cu di
        _danhSach.addAll(
          jsonList.map((e) => MonHoc.fromJson(e)).toList(),
        );
      });
    }
  }


  // --- Hàm hiển thị form nhập ---
  void _hienThiFormThem() async{
    //Chờ hộp thoại trả về kết quả
    //showDialog gọi Widget HopThoaiThemMon được tách ra
    final ketQua = await showDialog<MonHoc>(
      context: context,
      builder: (context) => const HopThoaiThemMon(),
    );

    //Nếu có kết quả trả về (người dùng bấm lưu)
    if (ketQua != null) {
      setState(() {
        _danhSach.add(ketQua);
      });
      _luuDuLieu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thời khóa biểu"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _hienThiFormThem,
        child: const Icon(Icons.add, color: Colors.white),
      ),


      body: _danhSach.isEmpty
          ? const Center(child: Text("Chưa có lịch học nào"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _danhSach.length,
              itemBuilder: (context, index) {
                return TheMonHoc(
                  monHoc: _danhSach[index], 

                  //Hàm xử lý khi bấm vào (Mở màn hình chi tiết)
                  onBamVao: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManHinhChiTiet(
                          monHoc: _danhSach[index],

                          //Hàm xóa để dùng khi được màn hình chi tiết gọi
                          hamXoa: () {
                            setState(() {
                              _danhSach.removeAt(index);
                            });
                            _luuDuLieu();
                          },

                          //Hàm sửa dùng khi màn hình chi tiết gọi
                          hamSua: (monMoi) {
                            //Cập nhật phần tử trong danh sách
                            setState(() {
                              _danhSach[index] = monMoi;
                            });
                            _luuDuLieu(); 
                          }
                        ),
                      ),
                    );

                    //Load lại nếu người dùng có nhập ghi chú
                    setState(() {});
                      _luuDuLieu();  
                  },
                );
              },
            ),
    );
  }
}
