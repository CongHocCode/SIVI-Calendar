//lib/services/danh_sach_service.dart

//De dung jsonEncode jsonDecode 
//Để lưu dữ liệu
import '../models/mon_hoc.dart';
import 'database_helper.dart';
import 'notification_helper.dart';

class DanhSachService {
  //Biến chứa danh sách dữ liệu (private)
  List<MonHoc> _danhSach = [];

  //Getter
  List<MonHoc> get danhSach => _danhSach;

  // Hàm gộp ngày và giờ thành DateTime chuẩn
  DateTime _getDateTimeChuan(MonHoc mon) {
    try {
      // Tách chuỗi "07:30"
      final parts = mon.thoiGian.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Gộp với ngày học
      return DateTime(
        mon.ngayHoc.year,
        mon.ngayHoc.month,
        mon.ngayHoc.day,
        hour,
        minute,
      );
    } catch (e) {
      return mon.ngayHoc; // Nếu lỗi format giờ thì trả về ngày gốc (00:00)
    }
  }

  //--- 1. Đọc dữ liệu từ ổ cứng ---
  Future<void> loadData() async {
    _danhSach = await DatabaseHelper.instance.readAll();
  }


  //--- 2. Thêm môn ---
  Future<void> themMon(MonHoc mon) async {
    // 1. Lưu xuống SQL
    int idMoi = await DatabaseHelper.instance.create(mon);
    mon.id = idMoi; 
    _danhSach.add(mon);
    _sapXepListHienThi();

    // 2. Hẹn giờ thông báo (Bọc try-catch cho an toàn giống suaMon)
    if (mon.nhacTruoc > 0) { // Chỉ hẹn nếu có nhắc
      try {
        await NotificationHelper.henGioBaoThuc(
          id: idMoi,
          title: "Sắp đến giờ học: ${mon.tenMon}",
          body: "Phòng: ${mon.phongHoc} | Giờ: ${mon.thoiGian}",
          thoiGianHoc: _getDateTimeChuan(mon),
          phutNhacTruoc: mon.nhacTruoc,
        );
      } catch (e) {
        print("⚠️ Lỗi hẹn giờ khi thêm: $e");
      }
    }
  }
  //--- 3. Xóa môn ---
  Future<void> xoaMon(MonHoc mon) async {
    if (mon.id != null) {
      await DatabaseHelper.instance.delete(mon.id!); //Xóa trong DB
      _danhSach.remove(mon); // Xóa trên RAM

      // Hủy thông báo tương ứng
      await NotificationHelper.huyNhacNho(mon.id!);
    }
  }

  //--- 5. Sửa môn ---
  Future<void> suaMon(MonHoc monCu, MonHoc monMoi) async {
    // 1. [QUAN TRỌNG NHẤT] Chép ID từ cái cũ sang cái mới
    // Nếu thiếu dòng này, monMoi.id sẽ là null -> Không hẹn giờ được
    monMoi.id = monCu.id; 

    // 2. Cập nhật Database
    await DatabaseHelper.instance.update(monMoi);
    
    // 3. Cập nhật List trên RAM
    int index = _danhSach.indexOf(monCu);
    if (index != -1) {
      _danhSach[index] = monMoi;
      _sapXepListHienThi();

      // 4. Xử lý Thông báo
      // Chỉ làm khi có ID hợp lệ
      if (monMoi.id != null) {
        try {
          // a. Hủy cái hẹn giờ cũ (Dựa trên ID)
          await NotificationHelper.huyNhacNho(monMoi.id!);
         

          // b. Hẹn giờ mới (Nếu người dùng có đặt nhắc nhở > 0)
          if (monMoi.nhacTruoc > 0) {
            await NotificationHelper.henGioBaoThuc(
              id: monMoi.id!, // Dùng ID này để hẹn
              title: "Sắp đến giờ: ${monMoi.tenMon}",
              body: "Phòng: ${monMoi.phongHoc} | Giờ: ${monMoi.thoiGian}",
              thoiGianHoc: _getDateTimeChuan(monMoi),
              phutNhacTruoc: monMoi.nhacTruoc,
              // Nếu bạn chưa sửa hàm henGioBaoThuc nhận phút thì sửa lại logic trừ giờ ở đây
            );

          }
        } catch (e) {
          print("💀Lỗi thông báo khi sửa: $e");
        }
      }
    }
  }

  //Hàm làm mới (Xóa hết rồi nạp lại)
  Future<void> lamMoiDanhSach(List<MonHoc> listMoi) async {
    for (var m in _danhSach) {
      if (m.id != null) await DatabaseHelper.instance.delete(m.id!); //Xóa từng cái cho an toàn
    }
    _danhSach.clear();

    //Thêm mới
    for (var m in listMoi) {
      await themMon(m);
    }
  }
  
  // --- HÀM ĐỒNG BỘ THÔNG MINH (Dùng cho Web Scraping) ---
  Future<void> capNhatLichTuDong(List<MonHoc> danhSachMoi) async {
    if (danhSachMoi.isEmpty) return;

    // 1. Tìm khoảng thời gian của dữ liệu mới
    // Sắp xếp tạm để lấy ngày đầu và ngày cuối
    danhSachMoi.sort((a, b) => a.ngayHoc.compareTo(b.ngayHoc));
    
    DateTime minDate = danhSachMoi.first.ngayHoc;
    DateTime maxDate = danhSachMoi.last.ngayHoc;

    // Mở rộng maxDate ra cuối ngày để chắc chắn bao trọn
    maxDate = DateTime(maxDate.year, maxDate.month, maxDate.day, 23, 59, 59); //TODO: Hỏi lại tại sao


    // 2. Xóa dữ liệu cũ (Chỉ xóa Lịch học, giữ Lịch cá nhân)
    await DatabaseHelper.instance.deleteSchoolScheduleInRange(minDate, maxDate);
    
    // Đồng thời xóa khỏi List trên RAM để đồng bộ
    _danhSach.removeWhere((mon) => 
        mon.loaiSuKien == 0 && 
        mon.ngayHoc.compareTo(minDate) >= 0 && 
        mon.ngayHoc.compareTo(maxDate) <= 0
    );

    // 3. Thêm dữ liệu mới vào
    for (var mon in danhSachMoi) {
      // Lưu xuống DB
      int id = await DatabaseHelper.instance.create(mon);
      mon.id = id;
      
      // Thêm vào RAM
      _danhSach.add(mon);
      
      // Hẹn giờ thông báo (nếu cần)
      if (mon.nhacTruoc > 0) {
        try {
          await NotificationHelper.henGioBaoThuc(
            id: id,
            title: "Sắp học: ${mon.tenMon}",
            body: "Phòng: ${mon.phongHoc}",
            thoiGianHoc: _getDateTimeChuan(mon),
            phutNhacTruoc: mon.nhacTruoc,
          );
        } catch (_) {}
      }
    }

    _sapXepListHienThi(); // Sắp xếp lại lần cuối
  }


 //Hàm sắp xếp nội bộ trên RAM (cập nhật giao diện)
  void _sapXepListHienThi() {
    _danhSach.sort((a, b) {
      int cmp = a.ngayHoc.compareTo(b.ngayHoc);
      if (cmp != 0) return cmp;
      return a.thoiGian.compareTo(b.thoiGian);
    });
  }

}
