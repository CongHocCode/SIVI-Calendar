// lib/screens/man_hinh_lich.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/danh_sach_service.dart';
import '../models/mon_hoc.dart';
import 'man_hinh_chi_tiet.dart';
import '../widgets/the_mon_hoc.dart';
import '../widgets/hop_thoai_them.dart';
import '../services/notification_helper.dart';
import '../services/auto_start_helper.dart';
import '../services/backup_service.dart';
import 'man_hinh_dang_nhap_web.dart';
import 'package:shared_preferences/shared_preferences.dart'; //Lưu dữ liệu nhỏ, đơn giản, dạng key-value trên máy người dùng, giữ trạng thái giữa những lần mở app

class ManHinhLich extends StatefulWidget {
  const ManHinhLich({super.key});
  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  // Khởi tạo Service để quản lý dữ liệu
  final DanhSachService _service = DanhSachService();

  // Biến lưu ngày đầu tuần (Thứ 2) đang xem
  late DateTime _ngayDauTuan;

  @override
  void initState() {
    super.initState();
    NotificationHelper.xinQuyenThongBao(); //Xin quyền thông báo
    // 1. Logic tìm ngày Thứ 2 của tuần hiện tại
    final now = DateTime.now();
    // Reset giờ về 00:00:00 để so sánh cho chuẩn (Quan trọng!)
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Công thức: Lấy ngày hiện tại TRỪ ĐI (Thứ trong tuần - 1)
    _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1));

    _khoiTaoDuLieu();
    _checkFirstTime();
  }

  //Kiểm tra có phải lần đầu mở app không, nếu phải thì mở hướng dẫn
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance(); //Lấy một cái kho lưu trữ duy nhất (singleton)
    bool? daXemHuongDan = prefs.getBool('first_time_v1');  //Đọc thử xem có dòng nào là 'first_time_v1' chưa, nếu chưa từng mở thì kết quả là null, nếu đã mở và xem thì kết quả là true

    //Chưa mở app lần nào, hoặc chưa xem hướng dẫn thì cho xem hướng dẫn
    if (daXemHuongDan == null || daXemHuongDan == false) {
      // Chờ 1 chút cho UI vẽ xong rồi mới hiện Dialog
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) { //Kiểm tra màn hình lịch này còn đang hiện không
        //Hiện bảng hướng dẫn
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Chào mừng đến SIVI! 🐧"),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Đây là trợ lý lịch học cá nhân của bạn."),
                  SizedBox(height: 10),
                  Text("✨ Tính năng nổi bật:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("• Đồng bộ lịch từ Web trường (Menu 3 chấm)."),
                  Text("• Nhắc nhở lịch học tự động."),
                  Text("• Quản lý lịch cá nhân."),
                  SizedBox(height: 10),
                  Text("⚠️ Lưu ý quan trọng:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(
                      "Nếu bạn dùng OPPO/Xiaomi và gặp lỗi thông báo, hãy vào Menu > Sửa lỗi không báo để cấp quyền chạy nền nhé!"),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Lưu lại là đã xem (để lần sau vào app thì if trên check lại và không mở bảng hướng dẫn)
                  prefs.setBool('first_time_v1', true);
                  Navigator.pop(ctx);
                },
                child: const Text("Đã hiểu, bắt đầu thôi!"),
              )
            ],
          ),
        );
      }
    }
  }

  // Gọi Service đọc dữ liệu từ ổ cứng lên
  Future<void> _khoiTaoDuLieu() async {
    await _service.loadData();
    setState(() {}); // Vẽ lại màn hình khi có dữ liệu
  }

  // --- HÀM TẠO DỮ LIỆU MẪU (Dùng để test nhanh) ---
  void _taoDuLieuMau() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Hàm phụ trợ tạo nhanh object MonHoc
    MonHoc taoMon(String ten, int lechNgay, String gio, String phong) {
      return MonHoc(
        tenMon: ten,
        phongHoc: phong,
        thoiGian: gio,
        // Tính ngày dựa trên ngày hôm nay
        ngayHoc: today.add(Duration(days: lechNgay)),
        giangVien: "GV. Demo",
        ghiChu: "Dữ liệu mẫu tự động tạo",
        nhacTruoc: 15,
      );
    }

    // Tính độ lệch để về Thứ 2 tuần này
    int offsetThu2 = 1 - now.weekday;

    List<MonHoc> dataMau = [
      // Lịch tuần này
      taoMon("Lập trình C++", offsetThu2, "07:00", "B101"), // Thứ 2
      taoMon("Đại số tuyến tính", offsetThu2, "09:30", "A202"), // Thứ 2
      taoMon("Cấu trúc dữ liệu", offsetThu2 + 2, "13:00", "C303"), // Thứ 4
      taoMon("Tiếng Anh CN", offsetThu2 + 3, "07:00", "Online"), // Thứ 5

      // Lịch tuần sau (Cộng thêm 7 ngày)
      taoMon("Thực hành C++", offsetThu2 + 7, "07:00", "Lab 1"),
      taoMon("Kỹ năng mềm", offsetThu2 + 9, "08:00", "Hội trường"),
    ];

    // Gọi Service để lưu đè danh sách mới
    await _service.lamMoiDanhSach(dataMau);
    setState(() {}); // Vẽ lại màn hình

    // Hiện thông báo nhỏ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã tạo dữ liệu mẫu thành công!")),
    );
  }

  // --- Hàm hiển thị form nhập (Thêm mới) ---
  void _hienThiFormThem() async {
    // Sửa thành showDialog<dynamic> để nhận kiểu gì cũng được
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const HopThoaiThemMon(),
    );

    if (result != null) {
      // Kiểm tra xem nó trả về cái gì
      if (result is List<MonHoc>) {
        // Nếu là List -> Vòng lặp thêm
        for (var mon in result) {
          await _service.themMon(mon);
        }
      } else if (result is MonHoc) {
        // Nếu là 1 MonHoc -> Thêm lẻ
        await _service.themMon(result);
      }

      setState(() {});
    }
  }

  // --- Logic đổi tuần ---
  void _doiTuan(int soTuan) {
    setState(() {
      _ngayDauTuan = _ngayDauTuan.add(Duration(days: 7 * soTuan));
    });
  }

  // --- Logic về hôm nay ---
  void _veHomNay() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1));
    });
  }

  // Hàm phụ trợ kiểm tra 2 ngày có trùng nhau không
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính ngày cuối tuần (Chủ nhật)
    final ngayCuoiTuan = _ngayDauTuan.add(const Duration(days: 6));

    // 2. Logic lọc: Lấy từ Service ra và lọc những môn nằm trong tuần này
    final danhSachHienThi = _service.danhSach.where((mon) {
      // So sánh ngày: Mon >= DauTuan VÀ Mon < (CuoiTuan + 1 ngày)
      return mon.ngayHoc.compareTo(_ngayDauTuan) >= 0 &&
          mon.ngayHoc.compareTo(ngayCuoiTuan.add(const Duration(days: 1))) < 0;
    }).toList();

    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Màu nền hơi xám nhẹ cho nổi bật thẻ Card

      appBar: AppBar(
        toolbarHeight: 70, // Tăng chiều cao AppBar
        title: Row(
          children: [
            // --- PHẦN LOGO ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/penguin.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12), // Khoảng cách giữa logo và chữ

            // --- PHẦN TÊN APP & NGÀY THÁNG ---
            Expanded(
              // Dùng Expanded để tránh lỗi tràn màn hình
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "SIVI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900, // Cực đậm cho giống logo
                      letterSpacing: 1.2, // Giãn chữ ra một chút cho sang
                    ),
                  ),
                  Text(
                    "${DateFormat('dd/MM').format(_ngayDauTuan)} - ${DateFormat('dd/MM').format(_ngayDauTuan.add(const Duration(days: 6)))}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,

        // --- Các nút điều hướng & Menu ---
        actions: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _doiTuan(-1)),
          IconButton(icon: const Icon(Icons.today), onPressed: _veHomNay),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _doiTuan(1)),

          // Menu 3 chấm (Popup)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mau') {
                _taoDuLieuMau();
              } else if (value == 'xoa_het') {
                await _service
                    .lamMoiDanhSach([]); // Xóa sạch bằng cách nạp list rỗng
                setState(() {});
              }

              //Gọi hàm sửa lỗi
              else if (value == 'fix_loi') {
                AutoStartHelper.fixLoiThongBao(context);
              }

              //Gọi hàm Backup
              else if (value == 'backup') {
                await BackupService.taoBanSaoLuu(context, _service.danhSach);
              }

              //Gọi hàm restore
              else if (value == 'restore') {
                // Gọi hàm khôi phục (Bỏ tham số onSuccess nếu bạn đã sửa service trả về bool)
                bool thanhCong =
                    await BackupService.khoiPhucDuLieu(context, _service);

                if (thanhCong) {
                  // Vẽ lại màn hình ngay lập tức
                  setState(() {});

                  // Hiện hộp thoại hỏi đồng bộ Web
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Cập nhật dữ liệu?"),
                      content: const Text(
                          "Dữ liệu lịch học vừa khôi phục có thể đã cũ.\nBạn có muốn đăng nhập vào Web trường để đồng bộ lịch mới nhất không?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Không cần"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ManHinhDangNhapWeb()),
                            ).then((_) {
                              _khoiTaoDuLieu();
                            });
                          },
                          child: const Text("Đồng bộ ngay"),
                        ),
                      ],
                    ),
                  );
                }
              } else if (value == 'web') {
                // <--- THÊM LOGIC NÀY
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManHinhDangNhapWeb()),
                );

                // 2. Khi người dùng quay lại, gọi hàm đọc lại dữ liệu từ ổ cứng
                print("Đã quay về từ Web, đang tải lại dữ liệu...");
                await _khoiTaoDuLieu(); // (Hàm này gọi service.loadData() + setState())
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mau',
                child: Row(children: [
                  Icon(Icons.data_array, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Tạo dữ liệu mẫu")
                ]),
              ),
              const PopupMenuItem(
                value: 'xoa_het',
                child: Row(children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Xóa tất cả")
                ]),
              ),

              const PopupMenuDivider(), // Đường kẻ ngang cho đẹp
              const PopupMenuItem(
                value: 'backup',
                child: Row(children: [
                  Icon(Icons.cloud_upload, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Sao lưu dữ liệu")
                ]),
              ),

              const PopupMenuItem(
                value: 'restore',
                child: Row(children: [
                  Icon(Icons.cloud_download, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Khôi phục dữ liệu")
                ]),
              ),

              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'fix_loi',
                  child: Row(
                    children: [
                      Icon(Icons.build_circle, color: Colors.orange),
                      SizedBox(width: 10),
                      Text("Sửa lỗi không báo")
                    ],
                  )),

              const PopupMenuDivider(),
              // --- THÊM DÒNG NÀY ---
              const PopupMenuItem(
                value: 'web',
                child: Row(children: [
                  Icon(Icons.public, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Đồng bộ từ Web")
                ]),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _hienThiFormThem,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      // Hiển thị danh sách hoặc thông báo rỗng
      body: danhSachHienThi.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available,
                      size: 80, color: Colors.grey[300]), // Icon to đẹp
                  const SizedBox(height: 10),
                  Text("Tuần này rảnh rỗi!",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 80,
                  top: 10,
                  left: 10,
                  right: 10), // Padding dưới để không bị nút che
              itemCount: danhSachHienThi.length,
              itemBuilder: (context, index) {
                final mon = danhSachHienThi[index];

                // Format ngày hiển thị (VD: THỨ 2, 08/12)
                String ngayHienThi = DateFormat('EEEE, dd/MM', 'vi')
                    .format(mon.ngayHoc)
                    .toUpperCase();

                // Logic ẩn/hiện Header Ngày (Nhóm các môn cùng ngày lại)
                bool hienDauMuc = true;
                if (index > 0) {
                  if (isSameDay(
                      mon.ngayHoc, danhSachHienThi[index - 1].ngayHoc)) {
                    hienDauMuc = false;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- GIAO DIỆN HEADER NGÀY (ĐÃ NÂNG CẤP) ---
                    if (hienDauMuc)
                      Container(
                        margin: const EdgeInsets.only(top: 15, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100, // Nền xanh nhạt
                          borderRadius: BorderRadius.circular(20), // Bo tròn
                        ),
                        child: Text(
                          ngayHienThi,
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),

                    // --- THẺ MÔN HỌC ---
                    TheMonHoc(
                      monHoc: mon,
                      onBamVao: () async {
                        // Chuyển sang màn hình chi tiết
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManHinhChiTiet(
                              monHoc: mon,
                              // Truyền hàm xóa
                              hamXoa: () async {
                                await _service.xoaMon(mon);
                                setState(() {});
                              },
                              // Truyền hàm sửa
                              hamSua: (monMoi) async {
                                await _service.suaMon(mon, monMoi);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                        // Quay lại thì reload giao diện
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
