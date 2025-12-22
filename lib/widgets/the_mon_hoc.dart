import 'package:flutter/material.dart';
import '../models/mon_hoc.dart';

class TheMonHoc extends StatelessWidget {
  final MonHoc monHoc;
  final VoidCallback onBamVao;

  const TheMonHoc({
    super.key,
    required this.monHoc,
    required this.onBamVao,
  });

  @override
  Widget build(BuildContext context) {
    Color mauNen = Color(monHoc.mauSac);
    bool laLichCaNhan = monHoc.loaiSuKien == 1;
    IconData iconDaiDien = laLichCaNhan ? Icons.person : Icons.class_;
    Color mauHienThi = laLichCaNhan ? Colors.orange : mauNen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // 1. Tạo cái Hộp có bóng đổ và nền trắng (Nhưng KHÔNG vẽ viền ở đây)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Bo góc cho cái hộp
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      
      // 2. Dùng ClipRRect để cắt những phần thừa ra khỏi góc bo tròn
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // 3. Vẽ cái viền màu bên trái ở đây (Không khai báo borderRadius ở trong này nữa -> Hết lỗi)
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: mauHienThi, width: 6), // Viền trái đậm
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBamVao,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mauHienThi.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconDaiDien, color: mauHienThi, size: 24),
                    ),
                    const SizedBox(width: 15),
                    
                    // Nội dung chữ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monHoc.tenMon,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_filled, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(monHoc.thoiGian, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                              
                              const SizedBox(width: 12),
                              
                              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  monHoc.phongHoc.isEmpty ? "Không rõ" : monHoc.phongHoc,
                                  style: TextStyle(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (!laLichCaNhan && monHoc.giangVien.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "GV: ${monHoc.giangVien}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    Icon(Icons.chevron_right, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}