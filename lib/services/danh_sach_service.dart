//lib/services/danh_sach_service.dart

//De dung jsonEncode jsonDecode 
//Để lưu dữ liệu
import '../models/mon_hoc.dart';
import 'database_helper.dart';

class DanhSachService {
  //Biến chứa danh sách dữ liệu (private)
  List<MonHoc> _danhSach = [];

  //Getter
  List<MonHoc> get danhSach => _danhSach;

  //--- 1. Đọc dữ liệu từ ổ cứng ---
  Future<void> loadData() async {
    _danhSach = await DatabaseHelper.instance.readAll();
  }


  //--- 2. Thêm môn ---
  Future<void> themMon(MonHoc mon) async {
    //Lưu xuống sql -> Nó trả về cái ID mới sinh ra
    int idMoi = await DatabaseHelper.instance.create(mon);
    mon.id = idMoi; // Gán ID đó vào object trên RAM
    _danhSach.add(mon); //Thêm vào list hiển thị
    _sapXepListHienThi();
  }

  //--- 3. Xóa môn ---
  Future<void> xoaMon(MonHoc mon) async {
    if (mon.id != null) {
      await DatabaseHelper.instance.delete(mon.id!); //Xóa trong DB
      _danhSach.remove(mon); // Xóa trên RAM
    }
  }

  //--- 5. Sửa môn ---
  Future<void> suaMon(MonHoc monCu, MonHoc monMoi) async {
    monMoi.id = monCu.id;

    await DatabaseHelper.instance.update(monMoi); //Update DB

    //Update trên RAM
    int index =_danhSach.indexOf(monCu);
    if (index != -1) {
      _danhSach[index] = monMoi;
      _sapXepListHienThi();
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


 //Hàm sắp xếp nội bộ trên RAM (cập nhật giao diện)
  void _sapXepListHienThi() {
    _danhSach.sort((a, b) {
      int cmp = a.ngayHoc.compareTo(b.ngayHoc);
      if (cmp != 0) return cmp;
      return a.thoiGian.compareTo(b.thoiGian);
    });
  }

}
