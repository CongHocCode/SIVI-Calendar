import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;


//TODO: LỖI
class NotificationHelper {
  static final _notification = FlutterLocalNotificationsPlugin(); //Plugin

  // --- 1. KHỞI TẠO ---
  static Future<void> init() async {
    tz_data.initializeTimeZones(); 
    
    // [FIX QUAN TRỌNG]: Thiết lập múi giờ Việt Nam
    // Nếu không có dòng này, giờ báo thức có thể bị lệch (theo giờ UTC)
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    //Init setting cho android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    //Nhóm các setting lại, mốt có IOS thì thêm vào nữa
    const settings = InitializationSettings(android: androidSettings);

    //Init plugin
    await _notification.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Xử lý khi bấm vào thông báo
      },
    );
  }

  // --- 2. XIN QUYỀN ---
  static Future<void> xinQuyenThongBao() async {
    final androidImplementation = _notification.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // --- 3. HẸN GIỜ ---
  static Future<void> henGioBaoThuc({
    required int id,
    required String title,
    required String body,
    required DateTime thoiGianHoc,
    required int phutNhacTruoc,
  }) async {
    // Trừ đi số phút để nhắc trước
    final gioNhac = thoiGianHoc.subtract(Duration(minutes: phutNhacTruoc));
  
    // Nếu giờ nhắc đã qua thì thôi (return luôn để đỡ tốn tài nguyên)
    if (gioNhac.isBefore(DateTime.now())) {
      print("Giờ nhắc đã qua, không nhắc nữa");
      return;
    }
    

    await _notification.zonedSchedule(
      id,
      title,
      body,
      // Dùng múi giờ local (đã set là HCM ở trên)
      tz.TZDateTime.from(gioNhac, tz.local), 
      
      //Chi tiết thông báo
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lich_hoc_channel',
          'Lịch Học',
          // [FIX]: Thêm mô tả cho người dùng biết kênh này làm gì
          channelDescription: 'Nhắc nhở trước giờ học!',
          importance: Importance.max,
          priority: Priority.high,

          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder, //Khai báo đây là dạng reminder
        ),
      ),

      // Cấu hình lập lịch chính xác (Cần quyền SCHEDULE_EXACT_ALARM)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
   
  }

  // --- 4. HỦY HẸN GIỜ ---
  static Future<void> huyNhacNho(int id) async {
    await _notification.cancel(id);
  }
}