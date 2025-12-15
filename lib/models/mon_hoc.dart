// lib/models/mon_hoc.dart

class MonHoc {
  int? id;
  String tenMon;
  String phongHoc;
  String thoiGian;
  DateTime ngayHoc;
  String ghiChu;
  String giangVien;

  MonHoc({
    this.id,
    required this.tenMon,
    required this.phongHoc,
    required this.thoiGian,
    required this.ngayHoc,
    required this.giangVien,
    this.ghiChu = "",
  });

  //Ham bien object thanh Map (chuyen thanh json)
  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'tenMon' : tenMon,
      'phongHoc': phongHoc,
      'thoiGian' : thoiGian,
      'ngayHoc' : ngayHoc.toIso8601String(), //Convert dưới dạng chuỗi ISO-8601 (2025-12-08T00:00:00) TOASK
      'ghiChu' : ghiChu,
      'giangVien' : giangVien,
    };
  }

  //Ham bien Map thanh Object de doc du lieu TOASK
  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      id: json['id'],
      tenMon: json['tenMon'],
      phongHoc: json['phongHoc'],
      thoiGian: json['thoiGian'],
      ngayHoc: DateTime.parse(json['ngayHoc']), //Parse chuỗi thành ngày
      ghiChu: json['ghiChu'] ?? "", //null thi lay rong
      giangVien: json['giangVien'],
    );
  }
}