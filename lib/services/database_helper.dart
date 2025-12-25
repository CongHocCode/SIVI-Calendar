import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mon_hoc.dart';


class DatabaseHelper {
  // Singleton: Chỉ tạo 1 kết nối duy nhất trong toàn app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter để lấy database (nếu chưa có thì mở, có rồi thì dùng lại)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lich_hoc.db');
    return _database!;
  }

  //Khởi tạo và tạo bảng
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); //Hỏi hdh xem thư mục lưu db ở đâu
    final path = join(dbPath, filePath); //Kết hợp đường dẫn và tên file để mở
    
    return await openDatabase(path, version: 1, onCreate: _createDB); //Thấy thì dùng không thì tạo DB mới
  }

  //Câu lệnh SQL tạo bảng (chạy 1 lần duy nhất khi cài app)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE monhoc (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenMon TEXT NOT NULL,
        phongHoc TEXT NOT NULL,
        thoiGian TEXT NOT NULL,
        ngayHoc TEXT NOT NULL,
        ghiChu TEXT,
        giangVien TEXT,
        nhacTruoc INTEGER,
        mauSac INTEGER,
        loaiSuKien INTEGER
      )
    ''');
  }

  //CRUD

  //Create
  Future<int> create(MonHoc mon) async {
    final db = await instance.database;
    //Lấy mpap dữ liệu ra
    final map = mon.toJson();

    // 2. [QUAN TRỌNG] Xóa trường 'id' khỏi map
    // Để đảm bảo SQL tự động tăng (Auto Increment), không chèn đè ID cũ
    map.remove('id'); 

    // insert trả về id dòng vừa thêm
    return await db.insert('monhoc', map);
  }

  //Read
  Future<List<MonHoc>> readAll() async {
    final db = await instance.database;
    final result = await db.query('monhoc', orderBy: 'ngayHoc ASC'); //Sort bằng sql
    return result.map((json) => MonHoc.fromJson(json)). toList();
  }

  //Update
  Future<int> update(MonHoc mon) async {
    final db = await instance.database;
    return await db.update(
      'monhoc',
      mon.toJson(),
      where: 'id = ?', //Tìm dòng có id bằng
      whereArgs: [mon.id], //id của môn này
    );
  }

  //Delete
  Future<int> delete(int id) async {
    final db = await instance.database; //Dùng để check xem liệu DB đã mở chưa
    return await db.delete(
      'monhoc',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hàm xóa lịch học (loaiSuKien = 0) trong khoảng thời gian cụ thể
  Future<int> deleteSchoolScheduleInRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    
    // Chuyển ngày sang chuỗi ISO8601 để so sánh trong SQL
    // start: Lấy đầu ngày (00:00:00)
    // end: Lấy cuối ngày (23:59:59) hoặc đơn giản là so sánh chuỗi ngày
    
    return await db.delete(
      'monhoc',
      where: 'loaiSuKien = 0 AND ngayHoc >= ? AND ngayHoc <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }
}