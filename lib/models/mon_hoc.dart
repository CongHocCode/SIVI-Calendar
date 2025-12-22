class MonHoc {
  int? id; //id để phân biệt rồi lưu và DB
  String tenMon; //đóng vai trò là tên sự kiện chung
  String phongHoc; // Với lịch cá nhân, cái này đóng vai trò là "Địa điểm"
  String thoiGian;
  DateTime ngayHoc;
  String ghiChu;
  String giangVien; // Lịch cá nhân thì cái này để rỗng
  int nhacTruoc;
  int mauSac;
  int loaiSuKien; // <--- THÊM BIẾN NÀY (0: Học, 1: Cá nhân)

  MonHoc({
    this.id,
    required this.tenMon,
    required this.phongHoc,
    required this.thoiGian,
    required this.ngayHoc,
    this.giangVien = "",
    this.ghiChu = "",
    this.nhacTruoc = 15,
    this.mauSac = 0xFF2196F3,
    this.loaiSuKien = 0, // <--- Mặc định là 0 (Lịch học)
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenMon': tenMon,
      'phongHoc': phongHoc,
      'thoiGian': thoiGian,
      'ngayHoc': ngayHoc.toIso8601String(),
      'ghiChu': ghiChu,
      'giangVien': giangVien,
      'nhacTruoc': nhacTruoc,
      'mauSac': mauSac,
      'loaiSuKien': loaiSuKien, // <--- Lưu vào DB
    };
  }

  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      id: json['id'],
      tenMon: json['tenMon'],
      phongHoc: json['phongHoc'],
      thoiGian: json['thoiGian'],
      ngayHoc: DateTime.parse(json['ngayHoc']),
      ghiChu: json['ghiChu'] ?? "",
      giangVien: json['giangVien'] ?? "",
      nhacTruoc: json['nhacTruoc'] ?? 15,
      mauSac: json['mauSac'] ?? 0xFF2196F3,
      loaiSuKien: json['loaiSuKien'] ?? 0, // <--- Đọc ra
    );
  }
}