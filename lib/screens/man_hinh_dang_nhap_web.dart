// lib/screens/man_hinh_dang_nhap_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import '../models/mon_hoc.dart';
import '../services/danh_sach_service.dart';

class ManHinhDangNhapWeb extends StatefulWidget {
  const ManHinhDangNhapWeb({super.key});

  @override
  State<ManHinhDangNhapWeb> createState() => _ManHinhDangNhapWebState();
}

class _ManHinhDangNhapWebState extends State<ManHinhDangNhapWeb> {
  //Controller, dạng như cái textController chỗ form thêm
  InAppWebViewController? webViewController;
  
  // Link web trường
  final String urlTrangWeb = "https://portal.ut.edu.vn/"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng nhập & Đồng bộ"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // Nút kích hoạt Bot
          IconButton(
            icon: const Icon(Icons.auto_mode),
            tooltip: "Chạy Auto Bot",
            onPressed: () async {
              // 1. Hiện bảng chọn số tuần
              int? soTuanChon = await showDialog<int>(
                context: context,
                builder: (ctx) => SimpleDialog( //Giao diện hỏi số tuần quét cho hàm bot chạy
                  title: const Text("Chọn thời gian quét"),
                  children: [
                    SimpleDialogOption(
                      padding: const EdgeInsets.all(15),
                      child: const Text("⚡ Quét nhanh (5 tuần tới)(Khuyến khích)", style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(ctx, 5),
                    ),
                    SimpleDialogOption(
                      padding: const EdgeInsets.all(15),
                      child: const Text("☀️ Học kỳ Hè (10 tuần)", style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(ctx, 10),
                    ),
                    SimpleDialogOption(
                      padding: const EdgeInsets.all(15),
                      child: const Text("📚 Học kỳ Chính (18 tuần)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      onPressed: () => Navigator.pop(ctx, 18),
                    ),
                    SimpleDialogOption(
                      padding: const EdgeInsets.all(15),
                      child: const Text("🗓️ Cả nửa năm (25 tuần)", style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(ctx, 25),
                    ),
                  ],
                ),
              );

              // 2. Nếu đã chọn thì chạy Bot
              if (soTuanChon != null) {
                _chayAutoBot(soTuanChon);
              }
            },
          )
        ],
      ),

      //Widget hiển thị trang web bên trong App
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(urlTrangWeb)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true, //Cho phép web chạy JS
          domStorageEnabled: true, //Cho phép lưu đăng nhập (Cookie/Session)
        ),
        //Khi web tạo xong, nó đưa mình controller
        onWebViewCreated: (controller) {
          webViewController = controller; //Gán vào biến controller tạo ở trên để dùng
        },
      ),
    );
  }

  // --- HÀM BOT TỰ ĐỘNG ---
  Future<void> _chayAutoBot(int soTuan) async {
    // Lệnh JS bấm nút Next (MUI Button)
    // Tìm nút có nhãn có nhãn aria-label="Tuần sau" (tìm được trên web trường, chỗ cái nút mũi tên chuyển tuần) rồi click()
    const String jsClickNext = "document.querySelector('button[aria-label=\"Tuần sau\"]').click();";

    List<MonHoc> tongHopLich = [];
    final DanhSachService service = DanhSachService();
    int soTuanLienTiepRong = 0; // Biến đếm để dừng sớm nếu hết lịch

    // Hiện Loading chặn màn hình
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false, //Không cho pop ra màn hình trước đó
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Bot đang cào dữ liệu...", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Vui lòng giữ màn hình sáng"),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      for (int i = 0; i < soTuan; i++) {
        print("🤖 Bot đang xử lý tuần thứ ${i + 1}...");

        // A. Lấy HTML của web
        // document.documentElement.outerHTML là lệnh JS lấy code HTML ==> thành 1 String
        String? html = await webViewController!.evaluateJavascript(source: "document.documentElement.outerHTML");
        
        if (html != null) {
          // B. Gửi HTML cho hàm phân tích
          //Hàm này trả về danh sách các môn tìm thấy trong HTML
          List<MonHoc> lichTuanNay = await _phanTichHTML_TraVeList(html);
          
          //Check coi lịch tuần đang quét có trống không
          if (lichTuanNay.isEmpty) {
            soTuanLienTiepRong++; 
          } else {
            soTuanLienTiepRong = 0; // Reset nếu có môn
            tongHopLich.addAll(lichTuanNay); //Gom vào danh sách tổng
          }
        }

        // C. Kiểm tra dừng sớm (Nếu 3 tuần liên tiếp không có gì -> Hết kỳ)
        if (soTuanLienTiepRong >= 3) {
           print("🛑 Dừng bot sớm vì 3 tuần liên tiếp không có lịch.");
           break; 
        }

        // D. Bấm nút Next (Trừ lần cuối)
        if (i < soTuan - 1) {
          await webViewController!.evaluateJavascript(source: jsClickNext);
          // Đợi web load (Web trường thường chậm, để 3-4s cho chắc) nếu không chờ, có khả năng cào lại trang cũ của tuần trước đó
          await Future.delayed(const Duration(seconds: 4));
        }
      }

      // E. Lưu vào Database (tránh gây trùng lặp)
      print("💾 Đang đồng bộ ${tongHopLich.length} môn vào Database...");
      if (tongHopLich.isNotEmpty) {
        await service.capNhatLichTuDong(tongHopLich);
      }

      // F. Kết thúc
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hoàn tất! Đã thêm ${tongHopLich.length} buổi học.")),
        );
        Navigator.pop(context); // Quay về màn hình lịch
      }

    } catch (e) {
      print("Lỗi Bot: $e");
      if (mounted) Navigator.pop(context); // Tắt loading nếu lỗi
    }
    
  }

  // --- HÀM PHÂN TÍCH HTML (Trả về List) ---
  Future<List<MonHoc>> _phanTichHTML_TraVeList(String htmlString) async {
    List<MonHoc> ketQua = [];
    try {
      //Dùng thư viện 'html' để biến chuỗi String có được ở bot thành cây DOM để dễ tìm thẻ
      var document = parser.parse(htmlString);
      var tables = document.getElementsByTagName('table'); //Tìm tất cả thẻ table

      if (tables.isEmpty) return [];

      var tableLich = tables[0]; //Lấy bảng đầu tiên (theo trang portal uth)
      var rows = tableLich.getElementsByTagName('tr'); //Lấy tất cả dòng (tr)(table row - một hàng trong bảng)
      
      //Map để lưu lại: Cột 1 ngày nào, Cột 2 ngày nào, vì trường chơi lịch dọc
      Map<int, DateTime> mapNgayHoc = {};

      // 1. Quét Header lấy Ngày
      var headerRow = rows[0]; //Dòng đầu tiên là tiêu đề
      var headerCells = headerRow.getElementsByTagName('th'); // Thử tìm thẻ <th>
      if (headerCells.isEmpty) headerCells = headerRow.getElementsByTagName('td'); // Dự phòng (Cho có 🐧)

      //Regex: Tìm chuỗi dạng số/số/số (VD:22/12/2025 )
      RegExp dateRegex = RegExp(r"(\d{1,2})\/(\d{1,2})\/(\d{4})"); 

      for (int j = 0; j < headerCells.length; j++) {
        String rawHeader = headerCells[j].text.trim(); //Lấy chữ trong ô (VD: Thứ 2 22/12/2025)
        Match? match = dateRegex.firstMatch(rawHeader); //Tìm ngày trong chuỗi đó 
        if (match != null) {
          try {
            //Nếu tìm thấy, lưu vào vào Map. VD: Cột 1 -> 22/12/2025
            DateTime date = DateFormat('d/M/yyyy').parse(match.group(0)!);
            mapNgayHoc[j] = date; //j là cột, date là ngày ở cột đó
          } catch (_) {}
        }
      }

      // 2. Quét Dữ liệu từng ô 
      //Duyệt từ dòng thứ 1 trở đi (bỏ dòng header mới duyệt ở trên)
      for (int i = 1; i < rows.length; i++) {
        var cells = rows[i].getElementsByTagName('td'); //Tìm các ô có tag <td> (table data cell)
        if (cells.length < 2) continue; //cells: Là danh sách các ô (<td>) trong một dòng (<tr>). Dòng phân cách (như dòng chữ "Sáng", "Chiều", "Tối") trong bảng HTML thường chỉ có 1 ô duy nhất (nó dùng colspan để gộp cột).


        for (int j = 1; j < cells.length; j++) {
          //Chỉ xét những cột đã xác định được ngày
          if (mapNgayHoc.containsKey(j)) {
            String content = cells[j].text.trim();
            String innerHtml = cells[j].innerHtml;

            // 🛑 Lọc Tạm Ngưng
            if (content.contains("Tạm ngưng") || innerHtml.contains("Tạm ngưng")) {
               continue; 
            }

            // Logic nhận diện môn học - nếu ô có chữ "Tiết" và "Phòng" -> chắc chắn là môn học
            if (content.isNotEmpty && content.contains("Tiết") && content.contains("Phòng")) {
              String tenMon = "Môn học";
              String phong = "Chưa rõ";
              String gio = "07:00";
              String giangVien = "";

              try {
                // Tách Tên
                tenMon = content.split("Tiết")[0].trim(); //Dùng hàm split cắt chuỗi lấy Tên, Phòng
                
                // Tách Giờ
                RegExp timeRegex = RegExp(r'(\d{1,2}:\d{2})'); //Dùng regex lấy giờ, tương tự như cái lấy ngày ở trên
                var timeMatches = timeRegex.allMatches(content);
                if (timeMatches.isNotEmpty) { //Hàm firstMatch hoạt động theo logic con trỏ (Pointer): Nếu tìm thấy: Trả về một Object Match (Con trỏ hợp lệ).
                  gio = timeMatches.first.group(0)!; //timeMatches là danh sách các giờ tìm thấy trong ô. .first lấy cái giờ đầu tiên. group(0) : toàn bộ chuỗi KHỚP với regex
                }
                // Tách Phòng
                if (content.contains("Phòng:")) {
                   String temp = content.split("Phòng:")[1];
                   if (temp.contains("LMS")) temp = temp.split("LMS")[0];
                   if (temp.contains("Ghi chú")) temp = temp.split("Ghi chú")[0];
                   phong = temp.trim();
                }

                ketQua.add(MonHoc(
                  tenMon: tenMon,
                  phongHoc: phong,
                  thoiGian: gio,
                  ngayHoc: mapNgayHoc[j]!, //Lấy ngày tương ứng với cột j
                  giangVien: giangVien,
                  ghiChu: "Tự động đồng bộ",
                  nhacTruoc: 15,
                  mauSac: 0xFF2196F3,
                ));
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi phân tích: $e");
    }
    return ketQua; //trả về danh sách môn tìm được
  }
}