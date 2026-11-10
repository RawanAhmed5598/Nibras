// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

// void main() {
//   runApp(const HeartSafeApp());
// }

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// // ================== 1. الشاشة الرئيسية ==================
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             _buildStatusCard(),
//             const SizedBox(height: 30),
//             Expanded(
//               child: GridView.count(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 15,
//                 mainAxisSpacing: 15,
//                 children: [
//                   _buildActionButton(
//                     context,
//                     Icons.monitor_heart,
//                     'قياس النبض',
//                     Colors.pink,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const HeartRatePage(),
//                       ),
//                     ),
//                   ),
//                   _buildActionButton(
//                     context,
//                     Icons.accessible_forward,
//                     'نظام السقوط',
//                     Colors.orange,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const FallDetectionPage(),
//                       ),
//                     ),
//                   ),
//                   _buildActionButton(
//                     context,
//                     Icons.wifi_tethering,
//                     'الرادار والمسافة',
//                     Colors.blue,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const BroadcastPage(),
//                       ),
//                     ),
//                   ),
//                   _buildActionButton(
//                     context,
//                     Icons.medical_services,
//                     'طريقة الإنعاش',
//                     Colors.green,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const CprGuidePage(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.shield, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "النظام يعمل",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text("مراقبة السقوط نشطة", style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== 2. صفحة النبض (ESP32) ==================
// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});
//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage>
//     with SingleTickerProviderStateMixin {
//   bool isScanning = false;
//   int bpmValue = 0;
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   StreamSubscription? _scanSubscription;
//   ble.BluetoothDevice? targetDevice;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//       lowerBound: 0.8,
//       upperBound: 1.0,
//     );
//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );
//   }

//   void startScan() async {
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();
//     setState(() {
//       isScanning = true;
//       bpmValue = 0;
//     });
//     _controller.repeat(reverse: true);

//     await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
//     _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
//       for (ble.ScanResult r in results) {
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           _connectToDevice(r.device);
//           break;
//         }
//       }
//     });
//   }

//   void _connectToDevice(ble.BluetoothDevice device) async {
//     await device.connect();
//     List<ble.BluetoothService> services = await device.discoverServices();
//     for (var service in services) {
//       if (service.uuid.toString().contains("180d")) {
//         for (var char in service.characteristics) {
//           if (char.uuid.toString().contains("2a37")) {
//             await char.setNotifyValue(true);
//             char.lastValueStream.listen((value) {
//               if (value.length > 1 && mounted) {
//                 setState(() {
//                   bpmValue = value[1];
//                   isScanning = false;
//                   _controller.stop();
//                 });
//               }
//             });
//           }
//         }
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scanSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص النبض (ESP32)"),
//         backgroundColor: Colors.pink,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ScaleTransition(
//               scale: _scaleAnimation,
//               child: Icon(
//                 Icons.favorite,
//                 size: 100,
//                 color: bpmValue > 0 ? Colors.red : Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isScanning
//                   ? "جاري البحث..."
//                   : (bpmValue > 0 ? "$bpmValue BPM" : "اضغط لبدء الفحص"),
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             if (!isScanning)
//               ElevatedButton(
//                 onPressed: startScan,
//                 child: const Text("بدء الفحص"),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== 3. صفحة الرادار (تم إصلاح المنقذ ✅) ==================
// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});
//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   final Strategy strategy = Strategy.P2P_STAR;
//   String myUserName = "User_${Random().nextInt(100)}";
//   final String serviceId = "com.example.heart_safe";

//   bool isAdvertising = false;
//   bool isDiscovering = false;
//   String statusText = "جاهز للعمل";
//   double? distanceInMeters;
//   StreamSubscription<Position>? _rescuerLocationStream;

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   void _initialize() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//     ].request();
//   }

//   // --- وضع المصاب ---
//   void startBroadcastingSOS() async {
//     await Nearby().stopAllEndpoints();
//     bool a = await Nearby().startAdvertising(
//       myUserName,
//       strategy,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (endId, payload) {}),
//       onConnectionResult: (id, status) async {
//         if (status == Status.CONNECTED) {
//           Position pos = await Geolocator.getCurrentPosition();
//           Nearby().sendBytesPayload(
//             id,
//             Uint8List.fromList(utf8.encode("${pos.latitude},${pos.longitude}")),
//           );
//         }
//       },
//       onDisconnected: (id) => setState(() => statusText = "انقطع الاتصال"),
//       serviceId: serviceId,
//     );
//     setState(() {
//       isAdvertising = a;
//       statusText = a ? "بث الاستغاثة نشط 📡" : "فشل البث";
//     });
//   }

//   // --- وضع المنقذ (تم الإصلاح) ---
//   void startSearchingForSOS() async {
//     await Nearby().stopAllEndpoints();
//     bool d = await Nearby().startDiscovery(
//       myUserName,
//       strategy,
//       onEndpointFound: (id, name, sId) {
//         // بمجرد العثور على مصاب، نطلب الاتصال فوراً
//         Nearby().requestConnection(
//           myUserName,
//           id,
//           onConnectionInitiated: (id, info) {
//             Nearby().acceptConnection(
//               id,
//               onPayLoadRecieved: (endId, payload) {
//                 if (payload.type == PayloadType.BYTES) {
//                   String msg = utf8.decode(payload.bytes!);
//                   _startNavigation(msg);
//                 }
//               },
//             );
//           },
//           onConnectionResult: (id, status) {
//             if (status == Status.CONNECTED) _showRadarSheet();
//           },
//           onDisconnected: (id) => Navigator.pop(context),
//         );
//       },
//       onEndpointLost: (id) {},
//       serviceId: serviceId,
//     );
//     setState(() {
//       isDiscovering = d;
//       statusText = d ? "جاري البحث عن ضحايا... 🔍" : "فشل الرادار";
//     });
//   }

//   void _startNavigation(String coords) {
//     var parts = coords.split(',');
//     double lat = double.parse(parts[0]);
//     double lng = double.parse(parts[1]);

//     _rescuerLocationStream?.cancel();
//     _rescuerLocationStream = Geolocator.getPositionStream().listen((pos) {
//       setState(
//         () => distanceInMeters = Geolocator.distanceBetween(
//           pos.latitude,
//           pos.longitude,
//           lat,
//           lng,
//         ),
//       );
//     });
//   }

//   void _showRadarSheet() {
//     showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) {
//           Timer.periodic(const Duration(seconds: 1), (t) {
//             if (mounted) setModalState(() {});
//           });
//           return Container(
//             padding: const EdgeInsets.all(30),
//             width: double.infinity,
//             decoration: const BoxDecoration(
//               color: Colors.redAccent,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.radar, size: 60, color: Colors.white),
//                 Text(
//                   distanceInMeters == null
//                       ? "تحديد الموقع..."
//                       : "${distanceInMeters!.toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للهدف",
//                   style: TextStyle(color: Colors.white70),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     stopAll();
//                   },
//                   child: const Text("إنهاء المهمة"),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void stopAll() async {
//     await Nearby().stopAllEndpoints();
//     _rescuerLocationStream?.cancel();
//     setState(() {
//       isAdvertising = false;
//       isDiscovering = false;
//       distanceInMeters = null;
//       statusText = "تم الإيقاف";
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("الرادار")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (isDiscovering) const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text(
//               statusText,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: isAdvertising ? stopAll : startBroadcastingSOS,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//               ),
//               child: Text(isAdvertising ? "إيقاف البث" : "أنا مصاب"),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: isDiscovering ? stopAll : startSearchingForSOS,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//               child: Text(isDiscovering ? "إيقاف البحث" : "أنا منقذ"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== 4. نظام السقوط ==================
// class FallDetectionPage extends StatefulWidget {
//   const FallDetectionPage({super.key});
//   @override
//   State<FallDetectionPage> createState() => _FallDetectionPageState();
// }

// class _FallDetectionPageState extends State<FallDetectionPage> {
//   bool isFalling = false;
//   StreamSubscription? _sub;
//   @override
//   void initState() {
//     super.initState();
//     _sub = userAccelerometerEvents.listen((event) {
//       double acceleration = sqrt(
//         event.x * event.x + event.y * event.y + event.z * event.z,
//       );
//       if (acceleration > 30 && !isFalling) setState(() => isFalling = true);
//     });
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: isFalling ? Colors.red : Colors.white,
//       appBar: AppBar(title: const Text("كشف السقوط")),
//       body: Center(
//         child: Text(
//           isFalling ? "🚨 تم اكتشاف سقوط!" : "النظام يراقب حركتك...",
//           style: TextStyle(
//             fontSize: 20,
//             color: isFalling ? Colors.white : Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================== 5. دليل الإنعاش ==================
// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("دليل CPR")),
//       body: const Padding(
//         padding: EdgeInsets.all(20),
//         child: Text(
//           "1. تأكد من الأمان.\n2. اتصل بـ 997.\n3. ابدأ الضغطات الصدرية (100-120 في الدقيقة).",
//           style: TextStyle(fontSize: 18, height: 2),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // مستمع لتلقي بيانات النبض بصمت من الواجهة
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//     }
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false;

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true;

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       // ✅ استخدام المسمى الموحد لمنع خطأ البناء
//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }

// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true, // يبقى ظاهراً حتى يتم التصفير من التطبيق
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false, // 🚫 معطل لضمان استقرار الخدمة (ردم الخندق)
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // عرض آخر نبض مسجل كمعلومة ثابتة لا تتغير لتوفير الموارد
//     subText: lastBpm > 0
//         ? "آخر نبض مسجل: $lastBpm BPM"
//         : "جاري تحليل البيانات...",
//   );

//   await plugin.show(
//     911,
//     '🚨 تنبيه: تم رصد سقوط!',
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();

//     Future.delayed(const Duration(seconds: 1), () {
//       if (EmergencyController.isEmergencyActive) {
//         FlutterBackgroundService().invoke('resetEmergency');
//         setState(() => EmergencyController.isEmergencyActive = false);
//         print("🛡️ صمام الأمان ردم الخندق عند دخول الصفحة الرئيسية");
//       }
//     });
//     // 📡 الاستماع لفتح صفحة الطوارئ فقط
//     FlutterBackgroundService().on('triggerEmergency').listen((event) {
//       if (!EmergencyController.isEmergencyActive) {
//         _handleEmergencyJump();
//       }
//     });

//     // 🔄 إذا رجع المستخدم للرئيسية، نضمن أن الحالة العامة ليست "نشطة"
//     // لكي يستقبل السقطة القادمة بنجاح
//     FlutterBackgroundService().on('resetEmergency').listen((event) {
//       EmergencyController.isEmergencyActive = false;
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================
// // ================== صفحة المنقذ (الرادار الذكي) ==================
// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   // تخزين الضحايا المكتشفين: معرف الجهاز -> {مسافة، خط عرض، خط طول}
//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _foundSub;
//   StreamSubscription? _lostSub;

//   @override
//   void initState() {
//     super.initState();
//     _startRadarDiscovery();
//   }

//   void _startRadarDiscovery() {
//     // 1. الاستماع عند العثور على جهاز يبث استغاثة
//     _foundSub = FlutterBackgroundService().on('victimFound').listen((
//       event,
//     ) async {
//       if (event != null && mounted) {
//         String name = event['name']; // التنسيق المتوقع: HELP_24.123_45.456
//         if (name.startsWith("HELP_")) {
//           try {
//             var parts = name.split('_');
//             double vLat = double.parse(parts[1]);
//             double vLng = double.parse(parts[2]);

//             // حساب المسافة بيني وبين الضحية
//             Position myPos = await Geolocator.getCurrentPosition();
//             double dist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );

//             setState(() {
//               foundVictims[event['id']] = {
//                 'distance': dist,
//                 'lat': vLat,
//                 'lng': vLng,
//               };
//             });
//           } catch (e) {
//             debugPrint("Error parsing victim data: $e");
//           }
//         }
//       }
//     });

//     // 2. الاستماع عند اختفاء إشارة الضحية
//     _lostSub = FlutterBackgroundService().on('victimLost').listen((event) {
//       if (mounted && event != null) {
//         setState(() => foundVictims.remove(event['id']));
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _foundSub?.cancel();
//     _lostSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("رادار الإنقاذ"),
//         backgroundColor: Colors.green,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(15),
//             color: Colors.green.withOpacity(0.1),
//             child: const Text(
//               "الرادار يعمل تلقائياً ويرصد أي استغاثة HELP قريبة منك في الخلفية.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: Colors.green,
//               ),
//             ),
//           ),
//           foundVictims.isEmpty
//               ? const Expanded(
//                   child: Center(child: Text("جاري البحث عن إشارات استغاثة...")),
//                 )
//               : Expanded(
//                   child: ListView.builder(
//                     itemCount: foundVictims.length,
//                     itemBuilder: (context, index) {
//                       String id = foundVictims.keys.elementAt(index);
//                       var data = foundVictims[id]!;

//                       return Card(
//                         margin: const EdgeInsets.all(10),
//                         elevation: 3,
//                         child: ListTile(
//                           leading: const Icon(
//                             Icons.warning,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                           title: const Text(
//                             "تم رصد ضحية سقوط!",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "المسافة: ${data['distance'].toStringAsFixed(1)} متر",
//                           ),
//                           trailing: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             onPressed: () {
//                               // ✅ الآن سيعمل هذا السطر بنجاح بعد إضافة المكتبة والـ Import
//                               MapsLauncher.launchCoordinates(
//                                 data['lat'],
//                                 data['lng'],
//                               );
//                             },
//                             child: const Text(
//                               "توجه الآن",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//هذا الكود الاخير الافضل (تشيك بوينت)
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true, // يبقى ظاهراً حتى يتم التصفير من التطبيق
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false, // 🚫 معطل لضمان استقرار الخدمة (ردم الخندق)
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // عرض آخر نبض مسجل كمعلومة ثابتة لا تتغير لتوفير الموارد
//     subText: lastBpm > 0
//         ? "آخر نبض مسجل: $lastBpm BPM"
//         : "جاري تحليل البيانات...",
//   );

//   await plugin.show(
//     911,
//     '🚨 تنبيه: تم رصد سقوط!',
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();

//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================
// // ================== صفحة المنقذ (الرادار الذكي) ==================
// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   // تخزين الضحايا المكتشفين: معرف الجهاز -> {مسافة، خط عرض، خط طول}
//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _foundSub;
//   StreamSubscription? _lostSub;

//   @override
//   void initState() {
//     super.initState();
//     _startRadarDiscovery();
//   }

//   void _startRadarDiscovery() {
//     // 1. الاستماع عند العثور على جهاز يبث استغاثة
//     _foundSub = FlutterBackgroundService().on('victimFound').listen((
//       event,
//     ) async {
//       if (event != null && mounted) {
//         String name = event['name']; // التنسيق المتوقع: HELP_24.123_45.456
//         if (name.startsWith("HELP_")) {
//           try {
//             var parts = name.split('_');
//             double vLat = double.parse(parts[1]);
//             double vLng = double.parse(parts[2]);

//             // حساب المسافة بيني وبين الضحية
//             Position myPos = await Geolocator.getCurrentPosition();
//             double dist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );

//             setState(() {
//               foundVictims[event['id']] = {
//                 'distance': dist,
//                 'lat': vLat,
//                 'lng': vLng,
//               };
//             });
//           } catch (e) {
//             debugPrint("Error parsing victim data: $e");
//           }
//         }
//       }
//     });

//     // 2. الاستماع عند اختفاء إشارة الضحية
//     _lostSub = FlutterBackgroundService().on('victimLost').listen((event) {
//       if (mounted && event != null) {
//         setState(() => foundVictims.remove(event['id']));
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _foundSub?.cancel();
//     _lostSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("رادار الإنقاذ"),
//         backgroundColor: Colors.green,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(15),
//             color: Colors.green.withOpacity(0.1),
//             child: const Text(
//               "الرادار يعمل تلقائياً ويرصد أي استغاثة HELP قريبة منك في الخلفية.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: Colors.green,
//               ),
//             ),
//           ),
//           foundVictims.isEmpty
//               ? const Expanded(
//                   child: Center(child: Text("جاري البحث عن إشارات استغاثة...")),
//                 )
//               : Expanded(
//                   child: ListView.builder(
//                     itemCount: foundVictims.length,
//                     itemBuilder: (context, index) {
//                       String id = foundVictims.keys.elementAt(index);
//                       var data = foundVictims[id]!;

//                       return Card(
//                         margin: const EdgeInsets.all(10),
//                         elevation: 3,
//                         child: ListTile(
//                           leading: const Icon(
//                             Icons.warning,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                           title: const Text(
//                             "تم رصد ضحية سقوط!",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "المسافة: ${data['distance'].toStringAsFixed(1)} متر",
//                           ),
//                           trailing: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             onPressed: () {
//                               // ✅ الآن سيعمل هذا السطر بنجاح بعد إضافة المكتبة والـ Import
//                               MapsLauncher.launchCoordinates(
//                                 data['lat'],
//                                 data['lng'],
//                               );
//                             },
//                             child: const Text(
//                               "توجه الآن",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

// //احتمال انه اقوى من السابق من ناحية ظهور الاشعار
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true, // يبقى ظاهراً حتى يتم التصفير من التطبيق
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false, // 🚫 معطل لضمان استقرار الخدمة (ردم الخندق)
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // عرض آخر نبض مسجل كمعلومة ثابتة لا تتغير لتوفير الموارد
//     subText: lastBpm > 0
//         ? "آخر نبض مسجل: $lastBpm BPM"
//         : "جاري تحليل البيانات...",
//   );

//   await plugin.show(
//     911,
//     '🚨 تنبيه: تم رصد سقوط!',
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================
// // ================== صفحة المنقذ (الرادار الذكي) ==================
// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   // تخزين الضحايا المكتشفين: معرف الجهاز -> {مسافة، خط عرض، خط طول}
//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _foundSub;
//   StreamSubscription? _lostSub;

//   @override
//   void initState() {
//     super.initState();
//     _startRadarDiscovery();
//   }

//   void _startRadarDiscovery() {
//     // 1. الاستماع عند العثور على جهاز يبث استغاثة
//     _foundSub = FlutterBackgroundService().on('victimFound').listen((
//       event,
//     ) async {
//       if (event != null && mounted) {
//         String name = event['name']; // التنسيق المتوقع: HELP_24.123_45.456
//         if (name.startsWith("HELP_")) {
//           try {
//             var parts = name.split('_');
//             double vLat = double.parse(parts[1]);
//             double vLng = double.parse(parts[2]);

//             // حساب المسافة بيني وبين الضحية
//             Position myPos = await Geolocator.getCurrentPosition();
//             double dist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );

//             setState(() {
//               foundVictims[event['id']] = {
//                 'distance': dist,
//                 'lat': vLat,
//                 'lng': vLng,
//               };
//             });
//           } catch (e) {
//             debugPrint("Error parsing victim data: $e");
//           }
//         }
//       }
//     });

//     // 2. الاستماع عند اختفاء إشارة الضحية
//     _lostSub = FlutterBackgroundService().on('victimLost').listen((event) {
//       if (mounted && event != null) {
//         setState(() => foundVictims.remove(event['id']));
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _foundSub?.cancel();
//     _lostSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("رادار الإنقاذ"),
//         backgroundColor: Colors.green,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(15),
//             color: Colors.green.withOpacity(0.1),
//             child: const Text(
//               "الرادار يعمل تلقائياً ويرصد أي استغاثة HELP قريبة منك في الخلفية.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: Colors.green,
//               ),
//             ),
//           ),
//           foundVictims.isEmpty
//               ? const Expanded(
//                   child: Center(child: Text("جاري البحث عن إشارات استغاثة...")),
//                 )
//               : Expanded(
//                   child: ListView.builder(
//                     itemCount: foundVictims.length,
//                     itemBuilder: (context, index) {
//                       String id = foundVictims.keys.elementAt(index);
//                       var data = foundVictims[id]!;

//                       return Card(
//                         margin: const EdgeInsets.all(10),
//                         elevation: 3,
//                         child: ListTile(
//                           leading: const Icon(
//                             Icons.warning,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                           title: const Text(
//                             "تم رصد ضحية سقوط!",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "المسافة: ${data['distance'].toStringAsFixed(1)} متر",
//                           ),
//                           trailing: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             onPressed: () {
//                               // ✅ الآن سيعمل هذا السطر بنجاح بعد إضافة المكتبة والـ Import
//                               MapsLauncher.launchCoordinates(
//                                 data['lat'],
//                                 data['lng'],
//                               );
//                             },
//                             child: const Text(
//                               "توجه الآن",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//افضل حل تماما الى هذه اللحظه وهذا السطر , باقي الموقع ورصده
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================
// // ================== صفحة المنقذ (الرادار الذكي) ==================
// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   // تخزين الضحايا المكتشفين: معرف الجهاز -> {مسافة، خط عرض، خط طول}
//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _foundSub;
//   StreamSubscription? _lostSub;

//   @override
//   void initState() {
//     super.initState();
//     _startRadarDiscovery();
//   }

//   void _startRadarDiscovery() {
//     // 1. الاستماع عند العثور على جهاز يبث استغاثة
//     _foundSub = FlutterBackgroundService().on('victimFound').listen((
//       event,
//     ) async {
//       if (event != null && mounted) {
//         String name = event['name']; // التنسيق المتوقع: HELP_24.123_45.456
//         if (name.startsWith("HELP_")) {
//           try {
//             var parts = name.split('_');
//             double vLat = double.parse(parts[1]);
//             double vLng = double.parse(parts[2]);

//             // حساب المسافة بيني وبين الضحية
//             Position myPos = await Geolocator.getCurrentPosition();
//             double dist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );

//             setState(() {
//               foundVictims[event['id']] = {
//                 'distance': dist,
//                 'lat': vLat,
//                 'lng': vLng,
//               };
//             });
//           } catch (e) {
//             debugPrint("Error parsing victim data: $e");
//           }
//         }
//       }
//     });

//     // 2. الاستماع عند اختفاء إشارة الضحية
//     _lostSub = FlutterBackgroundService().on('victimLost').listen((event) {
//       if (mounted && event != null) {
//         setState(() => foundVictims.remove(event['id']));
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _foundSub?.cancel();
//     _lostSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("رادار الإنقاذ"),
//         backgroundColor: Colors.green,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(15),
//             color: Colors.green.withOpacity(0.1),
//             child: const Text(
//               "الرادار يعمل تلقائياً ويرصد أي استغاثة HELP قريبة منك في الخلفية.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: Colors.green,
//               ),
//             ),
//           ),
//           foundVictims.isEmpty
//               ? const Expanded(
//                   child: Center(child: Text("جاري البحث عن إشارات استغاثة...")),
//                 )
//               : Expanded(
//                   child: ListView.builder(
//                     itemCount: foundVictims.length,
//                     itemBuilder: (context, index) {
//                       String id = foundVictims.keys.elementAt(index);
//                       var data = foundVictims[id]!;

//                       return Card(
//                         margin: const EdgeInsets.all(10),
//                         elevation: 3,
//                         child: ListTile(
//                           leading: const Icon(
//                             Icons.warning,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                           title: const Text(
//                             "تم رصد ضحية سقوط!",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "المسافة: ${data['distance'].toStringAsFixed(1)} متر",
//                           ),
//                           trailing: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             onPressed: () {
//                               // ✅ الآن سيعمل هذا السطر بنجاح بعد إضافة المكتبة والـ Import
//                               MapsLauncher.launchCoordinates(
//                                 data['lat'],
//                                 data['lng'],
//                               );
//                             },
//                             child: const Text(
//                               "توجه الآن",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//قدرت اتوصل لخواص البث والانقاذ
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================

// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   bool isVictimMode = false;
//   bool isRescuerMode = false;
//   String statusMessage = "مختبر البيانات الطبية والمسافة";

//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _positionStream;

//   // معرف فريد للمستخدم
//   final String myUserName = "User_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";

//   @override
//   void initState() {
//     super.initState();
//     _requestAllPermissions();
//   }

//   // طلب جميع الأذونات عند بدء الصفحة
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.location,
//         Permission.locationAlways,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.nearbyWifiDevices,
//       ].request();
//     }
//   }

//   // 🛠️ دالة التصفير الصلب
//   Future<void> _prepareRadio() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Nearby().stopAllEndpoints();
//       _positionStream?.cancel();
//       if (mounted) {
//         setState(() => foundVictims.clear());
//       }
//     } catch (e) {
//       debugPrint("Cleanup Error: $e");
//     }
//   }

//   // ================== وضع الضحية (Victim Mode) ==================
//   void _toggleVictimMode() async {
//     await _prepareRadio();

//     if (isVictimMode) {
//       setState(() {
//         isVictimMode = false;
//         statusMessage = "توقف البث";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

//     try {
//       // 1. فحص تفعيل الموقع
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
//         return;
//       }

//       // 2. الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       setState(() => statusMessage = "⏳ جاري بدء البث...");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       // 3. الحصول على معدل النبض
//       int lastBpm = EmergencyController.currentBpm;

//       // 4. بدء البث باسم بسيط (بدون إحداثيات)
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Connection initiated with: $id");
//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               // يمكن استقبال رسائل من المنقذ هنا (اختياري)
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             debugPrint("✅ Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
//             }
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Disconnected from: $id");
//           if (mounted) {
//             setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isVictimMode = started;
//         isRescuerMode = false;
//         statusMessage = started
//             ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
//             : "❌ فشل البث - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
//       } else if (e.toString().contains('location')) {
//         errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Victim Mode Error: $e");
//     }
//   }

//   // ================== وضع المنقذ (Rescuer Mode) ==================
//   void _toggleRescuerMode() async {
//     await _prepareRadio();

//     if (isRescuerMode) {
//       setState(() {
//         isRescuerMode = false;
//         statusMessage = "توقف الرادار";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
//     await Future.delayed(const Duration(milliseconds: 1500));

//     try {
//       bool started = await Nearby().startDiscovery(
//         myUserName,
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           debugPrint("🔍 Found endpoint: $name (ID: $id)");

//           // التحقق من أن الاسم يبدأ بـ VICTIM
//           if (!name.startsWith("VICTIM_")) return;

//           // طلب الاتصال فوراً (المفتاح الأساسي!)
//           Nearby().requestConnection(
//             myUserName,
//             id,
//             onConnectionInitiated: (id, info) {
//               debugPrint("🤝 Connection initiated with: $id");

//               // قبول الاتصال واستقبال البيانات
//               Nearby().acceptConnection(
//                 id,
//                 onPayLoadRecieved: (endId, payload) async {
//                   if (payload.type == PayloadType.BYTES &&
//                       payload.bytes != null) {
//                     try {
//                       // فك تشفير البيانات
//                       String jsonData = utf8.decode(payload.bytes!);
//                       Map<String, dynamic> victimData = jsonDecode(jsonData);

//                       double vLat = victimData['lat'];
//                       double vLng = victimData['lng'];
//                       int vBpm = victimData['bpm'] ?? 0;

//                       // حساب المسافة الأولية
//                       Position myPos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       double dist = Geolocator.distanceBetween(
//                         myPos.latitude,
//                         myPos.longitude,
//                         vLat,
//                         vLng,
//                       );

//                       // حفظ بيانات الضحية
//                       if (mounted) {
//                         setState(() {
//                           foundVictims[id] = {
//                             'distance': dist,
//                             'lat': vLat,
//                             'lng': vLng,
//                             'bpm': vBpm,
//                             'name': name,
//                           };
//                         });
//                       }

//                       // بدء تتبع المسافة الحية
//                       _startLiveTracking(id, vLat, vLng);

//                       debugPrint(
//                         "✅ Victim data received: ${victimData.toString()}",
//                       );
//                     } catch (e) {
//                       debugPrint("❌ Error parsing victim data: $e");
//                     }
//                   }
//                 },
//               );
//             },
//             onConnectionResult: (id, status) {
//               if (status == Status.CONNECTED) {
//                 debugPrint("✅ Successfully connected to victim: $id");
//               } else {
//                 debugPrint("❌ Connection failed with: $id");
//               }
//             },
//             onDisconnected: (id) {
//               debugPrint("❌ Victim disconnected: $id");
//               if (mounted) {
//                 setState(() => foundVictims.remove(id));
//               }
//             },
//           );
//         },
//         onEndpointLost: (id) {
//           debugPrint("📡 Endpoint lost: $id");
//           if (mounted) {
//             setState(() => foundVictims.remove(id));
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isRescuerMode = started;
//         isVictimMode = false;
//         statusMessage = started
//             ? "🔍 الرادار يستقبل البيانات الطبية..."
//             : "❌ فشل الرادار - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Rescuer Mode Error: $e");
//     }
//   }

//   // ================== تتبع المسافة الحية ==================
//   void _startLiveTracking(String victimId, double vLat, double vLng) {
//     _positionStream?.cancel();
//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 1, // تحديث كل متر
//           ),
//         ).listen((myPos) {
//           if (mounted && foundVictims.containsKey(victimId)) {
//             double newDist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );
//             setState(() {
//               foundVictims[victimId]!['distance'] = newDist;
//             });
//           }
//         });
//   }

//   // ================== واجهة المستخدم ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("رادار المسافة والنبض"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildTestConsole(),
//           Expanded(
//             child: foundVictims.isEmpty
//                 ? _buildEmptyState()
//                 : _buildVictimsList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestConsole() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             statusMessage,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _modeButton(
//                 "بث ضحية",
//                 Icons.wifi_tethering,
//                 isVictimMode,
//                 Colors.red,
//                 _toggleVictimMode,
//               ),
//               _modeButton(
//                 "رادار منقذ",
//                 Icons.radar,
//                 isRescuerMode,
//                 Colors.green,
//                 _toggleRescuerMode,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _modeButton(
//     String label,
//     IconData icon,
//     bool isActive,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(isActive ? Icons.stop : icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive ? Colors.black87 : color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildVictimsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(15),
//       itemCount: foundVictims.length,
//       itemBuilder: (context, index) {
//         String id = foundVictims.keys.elementAt(index);
//         var data = foundVictims[id]!;
//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 5,
//           margin: const EdgeInsets.only(bottom: 15),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "الحالة الحيوية:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "${data['bpm']} BPM",
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 30),
//                 Text(
//                   "${data['distance'].toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للوصول",
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
//                     const SizedBox(width: 5),
//                     Text(
//                       "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
//                       style: TextStyle(fontSize: 11, color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isRescuerMode ? Icons.radar : Icons.info_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             isRescuerMode
//                 ? "جاري البحث عن ضحايا..."
//                 : "لا توجد إشارات نشطة حالياً",
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _prepareRadio();
//     super.dispose();
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//هذا الكود انجح كودد للان وفيه قدرت اضيف تقنية الضحيه والمنقذ + ارسال نبضات القلب , اللي باقي هو اضافة لصفحة الطوارئ انه فيها ايضا سيعلن النظام انه ضحيه , ثم بعد ذلك اضيف خاصية الاشعار للمنقذين + اجعل خاصية الانقاذ تكون تعمل بالخلفيه على الدوام نفس ماخاصية رصد السقوط تعمل والتطبيق ينتظرها
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String status = "🚨 جاري بدء رصد النبض...";
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 🚀 سر النجاح: تأخير بسيط لضمان استقرار البلوتوث بعد فتح الصفحة
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _forcePulseCheck();
//     });
//     _broadcastSOS();
//   }

//   // 🛠️ المحرك المستوحى تماماً من صفحة الفحص مع "تصفير" المسح
//   void _forcePulseCheck() async {
//     try {
//       // 1️⃣ الخطوة الذهبية: إيقاف أي مسح سابق (هذا ما يمنع تعليق "جاري البحث")
//       await ble.FlutterBluePlus.stopScan();

//       // التأكد من أن البلوتوث يعمل (On)
//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => status = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => status = "🔍 جاري رصد السوارة الآن...");

//       // 2️⃣ بدء المسح بوضع "السرعة القصوى" (lowLatency)
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           // نفس الشرط اللي نجح معك
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan(); // توقف فوراً عند الإيجاد

//             setState(() => status = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               // 3️⃣ الاتصال المباشر
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       // 4️⃣ تفعيل النبض فوراً
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && mounted) {
//                           setState(() {
//                             bpm = value[1];
//                             status = "🚨 يتم بث نبضك وموقعك للمنقذين";
//                           });
//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': bpm,
//                           });
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               _forcePulseCheck(); // إعادة محاولة عند الفشل
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("BT Error: $e");
//     }
//   }

//   // بث الاستغاثة (SOS)
//   void _broadcastSOS() async {
//     try {
//       Position pos = await Geolocator.getCurrentPosition();
//       String sosName = "HELP_${pos.latitude}_${pos.longitude}";
//       await Nearby().startAdvertising(
//         sosName,
//         Strategy.P2P_CLUSTER,
//         onConnectionInitiated: (id, info) =>
//             Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) {}),
//         onConnectionResult: (id, status) {},
//         onDisconnected: (id) {}, // ✅ مضاف لمنع خطأ البناء
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {}
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.warning, size: 100, color: Colors.white),
//             const Text(
//               "🚨 طوارئ رصد سقوط",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 status,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: const EdgeInsets.all(50),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 bpm > 0 ? "$bpm" : "--",
//                 style: const TextStyle(
//                   fontSize: 80,
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.red[900],
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               onPressed: () {
//                 FlutterBackgroundService().invoke('resetEmergency');
//                 Nearby().stopAdvertising();
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "أنا بخير - إيقاف",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================

// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   bool isVictimMode = false;
//   bool isRescuerMode = false;
//   String statusMessage = "مختبر البيانات الطبية والمسافة";

//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _positionStream;
//   int _currentBpm = 0; // ← تخزين النبض محلياً

//   // معرف فريد للمستخدم
//   final String myUserName = "User_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";

//   @override
//   void initState() {
//     super.initState();
//     _requestAllPermissions();
//     _loadLastBpm(); // ← تحميل آخر نبض مسجل
//   }

//   // تحميل آخر قيمة نبض من EmergencyController
//   void _loadLastBpm() {
//     setState(() {
//       _currentBpm = EmergencyController.currentBpm;
//       // إذا كانت القيمة 0، نستخدم قيمة افتراضية معقولة
//       if (_currentBpm == 0) {
//         _currentBpm = 72; // معدل نبض طبيعي افتراضي
//       }
//     });
//     debugPrint("📊 Current BPM loaded: $_currentBpm");
//   }

//   // طلب جميع الأذونات عند بدء الصفحة
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.location,
//         Permission.locationAlways,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.nearbyWifiDevices,
//       ].request();
//     }
//   }

//   // 🛠️ دالة التصفير الصلب
//   Future<void> _prepareRadio() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Nearby().stopAllEndpoints();
//       _positionStream?.cancel();
//       if (mounted) {
//         setState(() => foundVictims.clear());
//       }
//     } catch (e) {
//       debugPrint("Cleanup Error: $e");
//     }
//   }

//   // ================== وضع الضحية (Victim Mode) ==================
//   void _toggleVictimMode() async {
//     await _prepareRadio();

//     if (isVictimMode) {
//       setState(() {
//         isVictimMode = false;
//         statusMessage = "توقف البث";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

//     try {
//       // 1. فحص تفعيل الموقع
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
//         return;
//       }

//       // 2. الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       setState(() => statusMessage = "⏳ جاري بدء البث...");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       // 3. جلب آخر نبض محفوظ من SharedPreferences (نفس اللي يستخدمه كود السقوط)
//       int lastBpm = 0;
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         lastBpm = prefs.getInt('last_bpm') ?? 0;

//         // إذا ما لقينا قيمة محفوظة، نحاول من EmergencyController
//         if (lastBpm == 0) {
//           lastBpm = EmergencyController.currentBpm;
//         }

//         // إذا ما زال 0، نستخدم قيمة افتراضية
//         if (lastBpm == 0) {
//           lastBpm = 72; // معدل نبض طبيعي افتراضي
//         }
//       } catch (e) {
//         debugPrint("⚠️ Error loading BPM: $e");
//         lastBpm = EmergencyController.currentBpm > 0
//             ? EmergencyController.currentBpm
//             : 72;
//       }

//       debugPrint("📡 Broadcasting with BPM: $lastBpm (from SharedPreferences)");

//       // 4. بدء البث باسم بسيط (بدون إحداثيات)
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Connection initiated with: $id");
//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               // يمكن استقبال رسائل من المنقذ هنا (اختياري)
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             debugPrint("✅ Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
//             }
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Disconnected from: $id");
//           if (mounted) {
//             setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isVictimMode = started;
//         isRescuerMode = false;
//         statusMessage = started
//             ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
//             : "❌ فشل البث - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
//       } else if (e.toString().contains('location')) {
//         errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Victim Mode Error: $e");
//     }
//   }

//   // ================== وضع المنقذ (Rescuer Mode) ==================
//   void _toggleRescuerMode() async {
//     await _prepareRadio();

//     if (isRescuerMode) {
//       setState(() {
//         isRescuerMode = false;
//         statusMessage = "توقف الرادار";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
//     await Future.delayed(const Duration(milliseconds: 1500));

//     try {
//       bool started = await Nearby().startDiscovery(
//         myUserName,
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           debugPrint("🔍 Found endpoint: $name (ID: $id)");

//           // التحقق من أن الاسم يبدأ بـ VICTIM
//           if (!name.startsWith("VICTIM_")) return;

//           // طلب الاتصال فوراً (المفتاح الأساسي!)
//           Nearby().requestConnection(
//             myUserName,
//             id,
//             onConnectionInitiated: (id, info) {
//               debugPrint("🤝 Connection initiated with: $id");

//               // قبول الاتصال واستقبال البيانات
//               Nearby().acceptConnection(
//                 id,
//                 onPayLoadRecieved: (endId, payload) async {
//                   if (payload.type == PayloadType.BYTES &&
//                       payload.bytes != null) {
//                     try {
//                       // فك تشفير البيانات
//                       String jsonData = utf8.decode(payload.bytes!);
//                       Map<String, dynamic> victimData = jsonDecode(jsonData);

//                       double vLat = victimData['lat'];
//                       double vLng = victimData['lng'];
//                       int vBpm = victimData['bpm'] ?? 0;

//                       // حساب المسافة الأولية
//                       Position myPos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       double dist = Geolocator.distanceBetween(
//                         myPos.latitude,
//                         myPos.longitude,
//                         vLat,
//                         vLng,
//                       );

//                       // حفظ بيانات الضحية
//                       if (mounted) {
//                         setState(() {
//                           foundVictims[id] = {
//                             'distance': dist,
//                             'lat': vLat,
//                             'lng': vLng,
//                             'bpm': vBpm,
//                             'name': name,
//                           };
//                         });
//                       }

//                       // بدء تتبع المسافة الحية
//                       _startLiveTracking(id, vLat, vLng);

//                       debugPrint(
//                         "✅ Victim data received: ${victimData.toString()}",
//                       );
//                     } catch (e) {
//                       debugPrint("❌ Error parsing victim data: $e");
//                     }
//                   }
//                 },
//               );
//             },
//             onConnectionResult: (id, status) {
//               if (status == Status.CONNECTED) {
//                 debugPrint("✅ Successfully connected to victim: $id");
//               } else {
//                 debugPrint("❌ Connection failed with: $id");
//               }
//             },
//             onDisconnected: (id) {
//               debugPrint("❌ Victim disconnected: $id");
//               if (mounted) {
//                 setState(() => foundVictims.remove(id));
//               }
//             },
//           );
//         },
//         onEndpointLost: (id) {
//           debugPrint("📡 Endpoint lost: $id");
//           if (mounted) {
//             setState(() => foundVictims.remove(id));
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isRescuerMode = started;
//         isVictimMode = false;
//         statusMessage = started
//             ? "🔍 الرادار يستقبل البيانات الطبية..."
//             : "❌ فشل الرادار - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Rescuer Mode Error: $e");
//     }
//   }

//   // ================== تتبع المسافة الحية ==================
//   void _startLiveTracking(String victimId, double vLat, double vLng) {
//     _positionStream?.cancel();
//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 1, // تحديث كل متر
//           ),
//         ).listen((myPos) {
//           if (mounted && foundVictims.containsKey(victimId)) {
//             double newDist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );
//             setState(() {
//               foundVictims[victimId]!['distance'] = newDist;
//             });
//           }
//         });
//   }

//   // ================== واجهة المستخدم ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("رادار المسافة والنبض"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildTestConsole(),
//           Expanded(
//             child: foundVictims.isEmpty
//                 ? _buildEmptyState()
//                 : _buildVictimsList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestConsole() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             statusMessage,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _modeButton(
//                 "بث ضحية",
//                 Icons.wifi_tethering,
//                 isVictimMode,
//                 Colors.red,
//                 _toggleVictimMode,
//               ),
//               _modeButton(
//                 "رادار منقذ",
//                 Icons.radar,
//                 isRescuerMode,
//                 Colors.green,
//                 _toggleRescuerMode,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _modeButton(
//     String label,
//     IconData icon,
//     bool isActive,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(isActive ? Icons.stop : icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive ? Colors.black87 : color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildVictimsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(15),
//       itemCount: foundVictims.length,
//       itemBuilder: (context, index) {
//         String id = foundVictims.keys.elementAt(index);
//         var data = foundVictims[id]!;
//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 5,
//           margin: const EdgeInsets.only(bottom: 15),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "الحالة الحيوية:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "${data['bpm']} BPM",
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 30),
//                 Text(
//                   "${data['distance'].toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للوصول",
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
//                     const SizedBox(width: 5),
//                     Text(
//                       "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
//                       style: TextStyle(fontSize: 11, color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isRescuerMode ? Icons.radar : Icons.info_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             isRescuerMode
//                 ? "جاري البحث عن ضحايا..."
//                 : "لا توجد إشارات نشطة حالياً",
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _prepareRadio();
//     super.dispose();
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//الكود المكتمل اللي حققت فيه كل شي واللي صفحة الطوارئ فيها تقنية الاعلام بشأن السقوط ويقدر المنقذ يرصدها
//باقي اضيف خاصية الانقاذ في الخلفيه والاشعار للمنقذين
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String statusMessage = "🚨 جاري بدء رصد النبض..."; // ← تغيير الاسم
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   // معرف فريد للضحية
//   final String myUserName = "Emergency_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";
//   bool isBroadcasting = false;

//   @override
//   void initState() {
//     super.initState();
//     // بدء الإجراءات الطارئة بالترتيب
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _startEmergencyProtocol();
//     });
//   }

//   // 🚨 بروتوكول الطوارئ الكامل
//   void _startEmergencyProtocol() async {
//     // 1️⃣ بدء قراءة النبض
//     _forcePulseCheck();

//     // 2️⃣ الانتظار قليلاً لضمان الحصول على موقع دقيق
//     await Future.delayed(const Duration(seconds: 2));

//     // 3️⃣ بث الاستغاثة بالتقنية المتطورة
//     _broadcastSOSAdvanced();
//   }

//   // 🛠️ قراءة النبض من السوارة (نفس الكود الناجح)
//   void _forcePulseCheck() async {
//     try {
//       await ble.FlutterBluePlus.stopScan();

//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => statusMessage = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => statusMessage = "🔍 جاري رصد السوارة الآن...");

//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan();

//             setState(() => statusMessage = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) async {
//                         if (value.length > 1 && mounted) {
//                           int newBpm = value[1];
//                           setState(() {
//                             bpm = newBpm;
//                             statusMessage =
//                                 "🚨 يتم بث نبضك ($bpm BPM) وموقعك للمنقذين";
//                           });

//                           // حفظ النبض في SharedPreferences
//                           final prefs = await SharedPreferences.getInstance();
//                           await prefs.setInt('last_bpm', newBpm);

//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': newBpm,
//                           });

//                           debugPrint("💾 Emergency BPM saved: $newBpm");
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               debugPrint("❌ Connection error: $e");
//               // إعادة محاولة بعد 3 ثواني
//               Future.delayed(const Duration(seconds: 3), _forcePulseCheck);
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("❌ BT Error: $e");
//     }
//   }

//   // 🚨 بث الاستغاثة بالتقنية المتطورة (Payload-based)
//   void _broadcastSOSAdvanced() async {
//     if (isBroadcasting) return; // منع البث المزدوج

//     try {
//       // إيقاف أي بث سابق
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();

//       setState(() => statusMessage = "📍 جاري تحديد موقعك...");

//       // الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       debugPrint(
//         "📍 Location obtained: ${currentPos.latitude}, ${currentPos.longitude}",
//       );

//       // جلب آخر نبض محفوظ
//       int lastBpm = bpm;
//       if (lastBpm == 0) {
//         try {
//           final prefs = await SharedPreferences.getInstance();
//           lastBpm = prefs.getInt('last_bpm') ?? 72;
//         } catch (e) {
//           lastBpm = 72;
//         }
//       }

//       debugPrint("🚨 Starting SOS broadcast with BPM: $lastBpm");

//       // بدء البث باسم بسيط
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Emergency: Connection initiated with rescuer: $id");

//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               debugPrint("📨 Received message from rescuer");
//             },
//           );
//         },
//         onConnectionResult: (id, connectionStatus) async {
//           if (connectionStatus == Status.CONNECTED) {
//             debugPrint("✅ Emergency: Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'emergency': true, // علامة أن هذه حالة طوارئ
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "✅ تم إرسال بياناتك للمنقذ!");
//             }

//             debugPrint("📡 Emergency data sent successfully");
//           } else {
//             debugPrint("❌ Connection failed with rescuer: $id");
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Rescuer disconnected: $id");
//           if (mounted) {
//             setState(
//               () => statusMessage = "⚠️ انقطع الاتصال - جاري إعادة البث...",
//             );
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isBroadcasting = started;
//         if (started) {
//           statusMessage = "📡 يتم بث موقعك ونبضك ($lastBpm BPM) للمنقذين...";
//         } else {
//           statusMessage = "❌ فشل البث - جاري إعادة المحاولة...";
//           // إعادة المحاولة بعد 3 ثواني
//           Future.delayed(const Duration(seconds: 3), _broadcastSOSAdvanced);
//         }
//       });

//       debugPrint(
//         started
//             ? "✅ SOS broadcast started successfully"
//             : "❌ SOS broadcast failed",
//       );
//     } catch (e) {
//       debugPrint("❌ Broadcast error: $e");
//       setState(() => statusMessage = "❌ خطأ في البث - جاري إعادة المحاولة...");

//       // إعادة المحاولة بعد 5 ثواني
//       Future.delayed(const Duration(seconds: 5), _broadcastSOSAdvanced);
//     }
//   }

//   // إيقاف كل شيء عند الخروج
//   void _stopEmergency() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();
//       await ble.FlutterBluePlus.stopScan();
//       _scanSubscription?.cancel();

//       FlutterBackgroundService().invoke('resetEmergency');

//       if (mounted) {
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint("❌ Stop error: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     Nearby().stopAdvertising();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // أيقونة التحذير
//                   const Icon(
//                     Icons.warning_rounded,
//                     size: 100,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(height: 20),

//                   // العنوان
//                   const Text(
//                     "🚨 حالة طوارئ",
//                     style: TextStyle(
//                       fontSize: 32,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),

//                   const Text(
//                     "تم رصد سقوط عنيف",
//                     style: TextStyle(fontSize: 18, color: Colors.white70),
//                   ),
//                   const SizedBox(height: 30),

//                   // رسالة الحالة
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(color: Colors.white30),
//                     ),
//                     child: Text(
//                       statusMessage,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // عرض النبض
//                   Container(
//                     padding: const EdgeInsets.all(40),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           bpm > 0 ? "$bpm" : "--",
//                           style: TextStyle(
//                             fontSize: 70,
//                             color: Colors.red[900],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           "BPM",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.red[700],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // مؤشر البث
//                   if (isBroadcasting)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.wifi_tethering,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "البث نشط",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 30),

//                   // زر الإيقاف
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.red[900],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 18,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 8,
//                     ),
//                     icon: const Icon(Icons.check_circle, size: 28),
//                     onPressed: _stopEmergency,
//                     label: const Text(
//                       "أنا بخير - إيقاف الطوارئ",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // معلومات إضافية
//                   Text(
//                     "يتم بث موقعك تلقائياً للمنقذين القريبين",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================

// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   bool isVictimMode = false;
//   bool isRescuerMode = false;
//   String statusMessage = "مختبر البيانات الطبية والمسافة";

//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _positionStream;
//   int _currentBpm = 0; // ← تخزين النبض محلياً

//   // معرف فريد للمستخدم
//   final String myUserName = "User_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";

//   @override
//   void initState() {
//     super.initState();
//     _requestAllPermissions();
//     _loadLastBpm(); // ← تحميل آخر نبض مسجل
//   }

//   // تحميل آخر قيمة نبض من EmergencyController
//   void _loadLastBpm() {
//     setState(() {
//       _currentBpm = EmergencyController.currentBpm;
//       // إذا كانت القيمة 0، نستخدم قيمة افتراضية معقولة
//       if (_currentBpm == 0) {
//         _currentBpm = 72; // معدل نبض طبيعي افتراضي
//       }
//     });
//     debugPrint("📊 Current BPM loaded: $_currentBpm");
//   }

//   // طلب جميع الأذونات عند بدء الصفحة
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.location,
//         Permission.locationAlways,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.nearbyWifiDevices,
//       ].request();
//     }
//   }

//   // 🛠️ دالة التصفير الصلب
//   Future<void> _prepareRadio() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Nearby().stopAllEndpoints();
//       _positionStream?.cancel();
//       if (mounted) {
//         setState(() => foundVictims.clear());
//       }
//     } catch (e) {
//       debugPrint("Cleanup Error: $e");
//     }
//   }

//   // ================== وضع الضحية (Victim Mode) ==================
//   void _toggleVictimMode() async {
//     await _prepareRadio();

//     if (isVictimMode) {
//       setState(() {
//         isVictimMode = false;
//         statusMessage = "توقف البث";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

//     try {
//       // 1. فحص تفعيل الموقع
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
//         return;
//       }

//       // 2. الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       setState(() => statusMessage = "⏳ جاري بدء البث...");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       // 3. جلب آخر نبض محفوظ من SharedPreferences (نفس اللي يستخدمه كود السقوط)
//       int lastBpm = 0;
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         lastBpm = prefs.getInt('last_bpm') ?? 0;

//         // إذا ما لقينا قيمة محفوظة، نحاول من EmergencyController
//         if (lastBpm == 0) {
//           lastBpm = EmergencyController.currentBpm;
//         }

//         // إذا ما زال 0، نستخدم قيمة افتراضية
//         if (lastBpm == 0) {
//           lastBpm = 72; // معدل نبض طبيعي افتراضي
//         }
//       } catch (e) {
//         debugPrint("⚠️ Error loading BPM: $e");
//         lastBpm = EmergencyController.currentBpm > 0
//             ? EmergencyController.currentBpm
//             : 72;
//       }

//       debugPrint("📡 Broadcasting with BPM: $lastBpm (from SharedPreferences)");

//       // 4. بدء البث باسم بسيط (بدون إحداثيات)
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Connection initiated with: $id");
//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               // يمكن استقبال رسائل من المنقذ هنا (اختياري)
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             debugPrint("✅ Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
//             }
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Disconnected from: $id");
//           if (mounted) {
//             setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isVictimMode = started;
//         isRescuerMode = false;
//         statusMessage = started
//             ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
//             : "❌ فشل البث - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
//       } else if (e.toString().contains('location')) {
//         errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Victim Mode Error: $e");
//     }
//   }

//   // ================== وضع المنقذ (Rescuer Mode) ==================
//   void _toggleRescuerMode() async {
//     await _prepareRadio();

//     if (isRescuerMode) {
//       setState(() {
//         isRescuerMode = false;
//         statusMessage = "توقف الرادار";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
//     await Future.delayed(const Duration(milliseconds: 1500));

//     try {
//       bool started = await Nearby().startDiscovery(
//         myUserName,
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           debugPrint("🔍 Found endpoint: $name (ID: $id)");

//           // التحقق من أن الاسم يبدأ بـ VICTIM
//           if (!name.startsWith("VICTIM_")) return;

//           // طلب الاتصال فوراً (المفتاح الأساسي!)
//           Nearby().requestConnection(
//             myUserName,
//             id,
//             onConnectionInitiated: (id, info) {
//               debugPrint("🤝 Connection initiated with: $id");

//               // قبول الاتصال واستقبال البيانات
//               Nearby().acceptConnection(
//                 id,
//                 onPayLoadRecieved: (endId, payload) async {
//                   if (payload.type == PayloadType.BYTES &&
//                       payload.bytes != null) {
//                     try {
//                       // فك تشفير البيانات
//                       String jsonData = utf8.decode(payload.bytes!);
//                       Map<String, dynamic> victimData = jsonDecode(jsonData);

//                       double vLat = victimData['lat'];
//                       double vLng = victimData['lng'];
//                       int vBpm = victimData['bpm'] ?? 0;

//                       // حساب المسافة الأولية
//                       Position myPos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       double dist = Geolocator.distanceBetween(
//                         myPos.latitude,
//                         myPos.longitude,
//                         vLat,
//                         vLng,
//                       );

//                       // حفظ بيانات الضحية
//                       if (mounted) {
//                         setState(() {
//                           foundVictims[id] = {
//                             'distance': dist,
//                             'lat': vLat,
//                             'lng': vLng,
//                             'bpm': vBpm,
//                             'name': name,
//                           };
//                         });
//                       }

//                       // بدء تتبع المسافة الحية
//                       _startLiveTracking(id, vLat, vLng);

//                       debugPrint(
//                         "✅ Victim data received: ${victimData.toString()}",
//                       );
//                     } catch (e) {
//                       debugPrint("❌ Error parsing victim data: $e");
//                     }
//                   }
//                 },
//               );
//             },
//             onConnectionResult: (id, status) {
//               if (status == Status.CONNECTED) {
//                 debugPrint("✅ Successfully connected to victim: $id");
//               } else {
//                 debugPrint("❌ Connection failed with: $id");
//               }
//             },
//             onDisconnected: (id) {
//               debugPrint("❌ Victim disconnected: $id");
//               if (mounted) {
//                 setState(() => foundVictims.remove(id));
//               }
//             },
//           );
//         },
//         onEndpointLost: (id) {
//           debugPrint("📡 Endpoint lost: $id");
//           if (mounted) {
//             setState(() => foundVictims.remove(id));
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isRescuerMode = started;
//         isVictimMode = false;
//         statusMessage = started
//             ? "🔍 الرادار يستقبل البيانات الطبية..."
//             : "❌ فشل الرادار - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Rescuer Mode Error: $e");
//     }
//   }

//   // ================== تتبع المسافة الحية ==================
//   void _startLiveTracking(String victimId, double vLat, double vLng) {
//     _positionStream?.cancel();
//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 1, // تحديث كل متر
//           ),
//         ).listen((myPos) {
//           if (mounted && foundVictims.containsKey(victimId)) {
//             double newDist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );
//             setState(() {
//               foundVictims[victimId]!['distance'] = newDist;
//             });
//           }
//         });
//   }

//   // ================== واجهة المستخدم ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("رادار المسافة والنبض"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildTestConsole(),
//           Expanded(
//             child: foundVictims.isEmpty
//                 ? _buildEmptyState()
//                 : _buildVictimsList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestConsole() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             statusMessage,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _modeButton(
//                 "بث ضحية",
//                 Icons.wifi_tethering,
//                 isVictimMode,
//                 Colors.red,
//                 _toggleVictimMode,
//               ),
//               _modeButton(
//                 "رادار منقذ",
//                 Icons.radar,
//                 isRescuerMode,
//                 Colors.green,
//                 _toggleRescuerMode,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _modeButton(
//     String label,
//     IconData icon,
//     bool isActive,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(isActive ? Icons.stop : icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive ? Colors.black87 : color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildVictimsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(15),
//       itemCount: foundVictims.length,
//       itemBuilder: (context, index) {
//         String id = foundVictims.keys.elementAt(index);
//         var data = foundVictims[id]!;
//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 5,
//           margin: const EdgeInsets.only(bottom: 15),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "الحالة الحيوية:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "${data['bpm']} BPM",
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 30),
//                 Text(
//                   "${data['distance'].toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للوصول",
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
//                     const SizedBox(width: 5),
//                     Text(
//                       "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
//                       style: TextStyle(fontSize: 11, color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isRescuerMode ? Icons.radar : Icons.info_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             isRescuerMode
//                 ? "جاري البحث عن ضحايا..."
//                 : "لا توجد إشارات نشطة حالياً",
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _prepareRadio();
//     super.dispose();
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatelessWidget {
//   const CprGuidePage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       Scaffold(appBar: AppBar(title: const Text("دليل الإنعاش")));
// }

//هذا اليوم الثاني ولقيت هذا الكود احتمال انه هو اخر ماتوصلت له ولكن مو اكيد
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ الخزان (State Holder) - مخزن الحالة الذي لا يضيع
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;

//   // 1️⃣ [جسر النبض]: استلام النبض من السوارة وإعادة بثه فوراً للواجهة (الأسطوانة الحمراء)
//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       // إرسال النبض فوراً لصفحة الطوارئ (التي تسمع updateBpmUi)
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 2️⃣ [استجواب الحالة]: يسمح لصفحة الرئيسية بسؤال الخدمة "هل هناك طوارئ فاتني رصدها؟"
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   // 🔄 دالة التصفير الذرية (Atomic Reset)
//   Future<void> atomicReset() async {
//     print("⚡ تنفيذ التصفير الذري: كسر الخندق وتحرير الحساسات");
//     isEmergencyMode = false; // تصفير الخزان

//     try {
//       await Nearby().stopAdvertising().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );
//       await Nearby().stopDiscovery().timeout(
//         const Duration(seconds: 1),
//         onTimeout: () {},
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "الحارس الشخصي نشط 🛡️",
//           content: "نظام الرصد يعمل وجاهز لرصد أي سقوط جديد",
//         );
//       }

//       await Nearby().startDiscovery(
//         "Guardian",
//         Strategy.P2P_CLUSTER,
//         onEndpointFound: (id, name, sid) {
//           if (name.startsWith("HELP_")) {
//             service.invoke('victimFound', {'id': id, 'name': name});
//           }
//         },
//         onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//         serviceId: "com.example.heart_safe",
//       );
//     } catch (e) {
//       debugPrint("Nearby Reset Error: $e");
//     }
//   }

//   // 📞 مستمع التصفير (من داخل التطبيق)
//   service.on('resetEmergency').listen((event) {
//     atomicReset();
//   });

//   // 🚨 [المسار الحرج]: مستمع الحساس (Accelerometer)
//   userAccelerometerEvents.listen((event) {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true; // قفل الخزان (تسجيل حالة الطوارئ)

//       // 1️⃣ التنفيذ الفوري (القفزة والبرقية الثابتة)
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "تم رصد سقوط! الموقع يبث الآن للمنقذين.",
//       );

//       // 🛰️ إدارة الشبكة في خيط خلفي معزول (Future)
//       Future(() async {
//         try {
//           await Nearby().stopDiscovery().timeout(
//             const Duration(seconds: 1),
//             onTimeout: () {},
//           );

//           Position pos =
//               await Geolocator.getCurrentPosition(
//                 timeLimit: const Duration(seconds: 5),
//               ).catchError(
//                 (e) => Position(
//                   latitude: 0.0,
//                   longitude: 0.0,
//                   timestamp: DateTime.now(),
//                   accuracy: 0.0,
//                   altitude: 0.0,
//                   altitudeAccuracy: 0.0,
//                   heading: 0.0,
//                   headingAccuracy: 0.0,
//                   speed: 0.0,
//                   speedAccuracy: 0.0,
//                 ),
//               );

//           String sosName = "HELP_${pos.latitude}_${pos.longitude}";

//           await Nearby().startAdvertising(
//             sosName,
//             Strategy.P2P_CLUSTER,
//             onConnectionInitiated: (id, info) =>
//                 Nearby().acceptConnection(id, onPayLoadRecieved: (i, p) {}),
//             onConnectionResult: (id, status) {
//               print("SOS Result: $status");
//             },
//             onDisconnected: (id) {
//               print("Disconnected");
//             },
//             serviceId: "com.example.heart_safe",
//           );
//         } catch (e) {
//           debugPrint("Advertising Failed: $e");
//         }
//       });
//     }
//   });

//   // الانطلاق الأول
//   if (service is AndroidServiceInstance) {
//     atomicReset();
//   }
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String statusMessage = "🚨 جاري بدء رصد النبض..."; // ← تغيير الاسم
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   // معرف فريد للضحية
//   final String myUserName = "Emergency_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";
//   bool isBroadcasting = false;

//   @override
//   void initState() {
//     super.initState();
//     // بدء الإجراءات الطارئة بالترتيب
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _startEmergencyProtocol();
//     });
//   }

//   // 🚨 بروتوكول الطوارئ الكامل
//   void _startEmergencyProtocol() async {
//     // 1️⃣ بدء قراءة النبض
//     _forcePulseCheck();

//     // 2️⃣ الانتظار قليلاً لضمان الحصول على موقع دقيق
//     await Future.delayed(const Duration(seconds: 5));

//     // 3️⃣ بث الاستغاثة بالتقنية المتطورة
//     _broadcastSOSAdvanced();
//   }

//   // 🛠️ قراءة النبض من السوارة (نفس الكود الناجح)
//   void _forcePulseCheck() async {
//     try {
//       await ble.FlutterBluePlus.stopScan();

//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => statusMessage = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => statusMessage = "🔍 جاري رصد السوارة الآن...");

//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan();

//             setState(() => statusMessage = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) async {
//                         if (value.length > 1 && mounted) {
//                           int newBpm = value[1];
//                           setState(() {
//                             bpm = newBpm;
//                             statusMessage =
//                                 "🚨 يتم بث نبضك ($bpm BPM) وموقعك للمنقذين";
//                           });

//                           // حفظ النبض في SharedPreferences
//                           final prefs = await SharedPreferences.getInstance();
//                           await prefs.setInt('last_bpm', newBpm);

//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': newBpm,
//                           });

//                           debugPrint("💾 Emergency BPM saved: $newBpm");
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               debugPrint("❌ Connection error: $e");
//               // إعادة محاولة بعد 3 ثواني
//               Future.delayed(const Duration(seconds: 3), _forcePulseCheck);
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("❌ BT Error: $e");
//     }
//   }

//   // 🚨 بث الاستغاثة بالتقنية المتطورة (Payload-based)
//   void _broadcastSOSAdvanced() async {
//     if (isBroadcasting) return; // منع البث المزدوج

//     try {
//       // إيقاف أي بث سابق
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();

//       setState(() => statusMessage = "📍 جاري تحديد موقعك...");

//       // الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       debugPrint(
//         "📍 Location obtained: ${currentPos.latitude}, ${currentPos.longitude}",
//       );

//       // جلب آخر نبض محفوظ
//       int lastBpm = bpm;
//       if (lastBpm == 0) {
//         try {
//           final prefs = await SharedPreferences.getInstance();
//           lastBpm = prefs.getInt('last_bpm') ?? 72;
//         } catch (e) {
//           lastBpm = 72;
//         }
//       }

//       debugPrint("🚨 Starting SOS broadcast with BPM: $lastBpm");

//       // بدء البث باسم بسيط
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Emergency: Connection initiated with rescuer: $id");

//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               debugPrint("📨 Received message from rescuer");
//             },
//           );
//         },
//         onConnectionResult: (id, connectionStatus) async {
//           if (connectionStatus == Status.CONNECTED) {
//             debugPrint("✅ Emergency: Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'emergency': true, // علامة أن هذه حالة طوارئ
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "✅ تم إرسال بياناتك للمنقذ!");
//             }

//             debugPrint("📡 Emergency data sent successfully");
//           } else {
//             debugPrint("❌ Connection failed with rescuer: $id");
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Rescuer disconnected: $id");
//           if (mounted) {
//             setState(
//               () => statusMessage = "⚠️ انقطع الاتصال - جاري إعادة البث...",
//             );
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isBroadcasting = started;
//         if (started) {
//           statusMessage = "📡 يتم بث موقعك ونبضك ($lastBpm BPM) للمنقذين...";
//         } else {
//           statusMessage = "❌ فشل البث - جاري إعادة المحاولة...";
//           // إعادة المحاولة بعد 3 ثواني
//           Future.delayed(const Duration(seconds: 3), _broadcastSOSAdvanced);
//         }
//       });

//       debugPrint(
//         started
//             ? "✅ SOS broadcast started successfully"
//             : "❌ SOS broadcast failed",
//       );
//     } catch (e) {
//       debugPrint("❌ Broadcast error: $e");
//       setState(() => statusMessage = "❌ خطأ في البث - جاري إعادة المحاولة...");

//       // إعادة المحاولة بعد 5 ثواني
//       Future.delayed(const Duration(seconds: 5), _broadcastSOSAdvanced);
//     }
//   }

//   // إيقاف كل شيء عند الخروج
//   void _stopEmergency() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();
//       await ble.FlutterBluePlus.stopScan();
//       _scanSubscription?.cancel();

//       FlutterBackgroundService().invoke('resetEmergency');

//       if (mounted) {
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint("❌ Stop error: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     Nearby().stopAdvertising();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // أيقونة التحذير
//                   const Icon(
//                     Icons.warning_rounded,
//                     size: 100,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(height: 20),

//                   // العنوان
//                   const Text(
//                     "🚨 حالة طوارئ",
//                     style: TextStyle(
//                       fontSize: 32,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),

//                   const Text(
//                     "تم رصد سقوط عنيف",
//                     style: TextStyle(fontSize: 18, color: Colors.white70),
//                   ),
//                   const SizedBox(height: 30),

//                   // رسالة الحالة
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(color: Colors.white30),
//                     ),
//                     child: Text(
//                       statusMessage,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // عرض النبض
//                   Container(
//                     padding: const EdgeInsets.all(40),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           bpm > 0 ? "$bpm" : "--",
//                           style: TextStyle(
//                             fontSize: 70,
//                             color: Colors.red[900],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           "BPM",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.red[700],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // مؤشر البث
//                   if (isBroadcasting)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.wifi_tethering,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "البث نشط",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 30),

//                   // زر الإيقاف
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.red[900],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 18,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 8,
//                     ),
//                     icon: const Icon(Icons.check_circle, size: 28),
//                     onPressed: _stopEmergency,
//                     label: const Text(
//                       "أنا بخير - إيقاف الطوارئ",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // معلومات إضافية
//                   Text(
//                     "يتم بث موقعك تلقائياً للمنقذين القريبين",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================

// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   bool isVictimMode = false;
//   bool isRescuerMode = false;
//   String statusMessage = "مختبر البيانات الطبية والمسافة";

//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _positionStream;
//   int _currentBpm = 0; // ← تخزين النبض محلياً

//   // معرف فريد للمستخدم
//   final String myUserName = "User_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";

//   @override
//   void initState() {
//     super.initState();
//     _requestAllPermissions();
//     _loadLastBpm(); // ← تحميل آخر نبض مسجل
//   }

//   // تحميل آخر قيمة نبض من EmergencyController
//   void _loadLastBpm() {
//     setState(() {
//       _currentBpm = EmergencyController.currentBpm;
//       // إذا كانت القيمة 0، نستخدم قيمة افتراضية معقولة
//       if (_currentBpm == 0) {
//         _currentBpm = 72; // معدل نبض طبيعي افتراضي
//       }
//     });
//     debugPrint("📊 Current BPM loaded: $_currentBpm");
//   }

//   // طلب جميع الأذونات عند بدء الصفحة
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.location,
//         Permission.locationAlways,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.nearbyWifiDevices,
//       ].request();
//     }
//   }

//   // 🛠️ دالة التصفير الصلب
//   Future<void> _prepareRadio() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Nearby().stopAllEndpoints();
//       _positionStream?.cancel();
//       if (mounted) {
//         setState(() => foundVictims.clear());
//       }
//     } catch (e) {
//       debugPrint("Cleanup Error: $e");
//     }
//   }

//   // ================== وضع الضحية (Victim Mode) ==================
//   void _toggleVictimMode() async {
//     await _prepareRadio();

//     if (isVictimMode) {
//       setState(() {
//         isVictimMode = false;
//         statusMessage = "توقف البث";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

//     try {
//       // 1. فحص تفعيل الموقع
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
//         return;
//       }

//       // 2. الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       setState(() => statusMessage = "⏳ جاري بدء البث...");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       // 3. جلب آخر نبض محفوظ من SharedPreferences (نفس اللي يستخدمه كود السقوط)
//       int lastBpm = 0;
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         lastBpm = prefs.getInt('last_bpm') ?? 0;

//         // إذا ما لقينا قيمة محفوظة، نحاول من EmergencyController
//         if (lastBpm == 0) {
//           lastBpm = EmergencyController.currentBpm;
//         }

//         // إذا ما زال 0، نستخدم قيمة افتراضية
//         if (lastBpm == 0) {
//           lastBpm = 72; // معدل نبض طبيعي افتراضي
//         }
//       } catch (e) {
//         debugPrint("⚠️ Error loading BPM: $e");
//         lastBpm = EmergencyController.currentBpm > 0
//             ? EmergencyController.currentBpm
//             : 72;
//       }

//       debugPrint("📡 Broadcasting with BPM: $lastBpm (from SharedPreferences)");

//       // 4. بدء البث باسم بسيط (بدون إحداثيات)
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Connection initiated with: $id");
//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               // يمكن استقبال رسائل من المنقذ هنا (اختياري)
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             debugPrint("✅ Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
//             }
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Disconnected from: $id");
//           if (mounted) {
//             setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isVictimMode = started;
//         isRescuerMode = false;
//         statusMessage = started
//             ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
//             : "❌ فشل البث - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
//       } else if (e.toString().contains('location')) {
//         errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Victim Mode Error: $e");
//     }
//   }

//   // ================== وضع المنقذ (Rescuer Mode) ==================
//   void _toggleRescuerMode() async {
//     await _prepareRadio();

//     if (isRescuerMode) {
//       setState(() {
//         isRescuerMode = false;
//         statusMessage = "توقف الرادار";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
//     await Future.delayed(const Duration(milliseconds: 1500));

//     try {
//       bool started = await Nearby().startDiscovery(
//         myUserName,
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           debugPrint("🔍 Found endpoint: $name (ID: $id)");

//           // التحقق من أن الاسم يبدأ بـ VICTIM
//           if (!name.startsWith("VICTIM_")) return;

//           // طلب الاتصال فوراً (المفتاح الأساسي!)
//           Nearby().requestConnection(
//             myUserName,
//             id,
//             onConnectionInitiated: (id, info) {
//               debugPrint("🤝 Connection initiated with: $id");

//               // قبول الاتصال واستقبال البيانات
//               Nearby().acceptConnection(
//                 id,
//                 onPayLoadRecieved: (endId, payload) async {
//                   if (payload.type == PayloadType.BYTES &&
//                       payload.bytes != null) {
//                     try {
//                       // فك تشفير البيانات
//                       String jsonData = utf8.decode(payload.bytes!);
//                       Map<String, dynamic> victimData = jsonDecode(jsonData);

//                       double vLat = victimData['lat'];
//                       double vLng = victimData['lng'];
//                       int vBpm = victimData['bpm'] ?? 0;

//                       // حساب المسافة الأولية
//                       Position myPos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       double dist = Geolocator.distanceBetween(
//                         myPos.latitude,
//                         myPos.longitude,
//                         vLat,
//                         vLng,
//                       );

//                       // حفظ بيانات الضحية
//                       if (mounted) {
//                         setState(() {
//                           foundVictims[id] = {
//                             'distance': dist,
//                             'lat': vLat,
//                             'lng': vLng,
//                             'bpm': vBpm,
//                             'name': name,
//                           };
//                         });
//                       }

//                       // بدء تتبع المسافة الحية
//                       _startLiveTracking(id, vLat, vLng);

//                       debugPrint(
//                         "✅ Victim data received: ${victimData.toString()}",
//                       );
//                     } catch (e) {
//                       debugPrint("❌ Error parsing victim data: $e");
//                     }
//                   }
//                 },
//               );
//             },
//             onConnectionResult: (id, status) {
//               if (status == Status.CONNECTED) {
//                 debugPrint("✅ Successfully connected to victim: $id");
//               } else {
//                 debugPrint("❌ Connection failed with: $id");
//               }
//             },
//             onDisconnected: (id) {
//               debugPrint("❌ Victim disconnected: $id");
//               if (mounted) {
//                 setState(() => foundVictims.remove(id));
//               }
//             },
//           );
//         },
//         onEndpointLost: (id) {
//           debugPrint("📡 Endpoint lost: $id");
//           if (mounted) {
//             setState(() => foundVictims.remove(id));
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isRescuerMode = started;
//         isVictimMode = false;
//         statusMessage = started
//             ? "🔍 الرادار يستقبل البيانات الطبية..."
//             : "❌ فشل الرادار - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Rescuer Mode Error: $e");
//     }
//   }

//   // ================== تتبع المسافة الحية ==================
//   void _startLiveTracking(String victimId, double vLat, double vLng) {
//     _positionStream?.cancel();
//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 1, // تحديث كل متر
//           ),
//         ).listen((myPos) {
//           if (mounted && foundVictims.containsKey(victimId)) {
//             double newDist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );
//             setState(() {
//               foundVictims[victimId]!['distance'] = newDist;
//             });
//           }
//         });
//   }

//   // ================== واجهة المستخدم ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("رادار المسافة والنبض"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildTestConsole(),
//           Expanded(
//             child: foundVictims.isEmpty
//                 ? _buildEmptyState()
//                 : _buildVictimsList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestConsole() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             statusMessage,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _modeButton(
//                 "بث ضحية",
//                 Icons.wifi_tethering,
//                 isVictimMode,
//                 Colors.red,
//                 _toggleVictimMode,
//               ),
//               _modeButton(
//                 "رادار منقذ",
//                 Icons.radar,
//                 isRescuerMode,
//                 Colors.green,
//                 _toggleRescuerMode,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _modeButton(
//     String label,
//     IconData icon,
//     bool isActive,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(isActive ? Icons.stop : icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive ? Colors.black87 : color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildVictimsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(15),
//       itemCount: foundVictims.length,
//       itemBuilder: (context, index) {
//         String id = foundVictims.keys.elementAt(index);
//         var data = foundVictims[id]!;
//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 5,
//           margin: const EdgeInsets.only(bottom: 15),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "الحالة الحيوية:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "${data['bpm']} BPM",
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 30),
//                 Text(
//                   "${data['distance'].toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للوصول",
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
//                     const SizedBox(width: 5),
//                     Text(
//                       "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
//                       style: TextStyle(fontSize: 11, color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isRescuerMode ? Icons.radar : Icons.info_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             isRescuerMode
//                 ? "جاري البحث عن ضحايا..."
//                 : "لا توجد إشارات نشطة حالياً",
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _prepareRadio();
//     super.dispose();
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatefulWidget {
//   const CprGuidePage({super.key});

//   @override
//   State<CprGuidePage> createState() => _CprGuidePageState();
// }

// class _CprGuidePageState extends State<CprGuidePage> {
//   final FlutterTts _tts = FlutterTts();
//   int _currentStep = 0;

//   // قائمة الخطوات باستخدام الصور المحلية (التي أضفتها في الـ assets)
//   final List<Map<String, String>> _cprSteps = [
//     {
//       "title": "تأكد من الأمان",
//       "desc":
//           "تأكد أن المكان آمن لك وللمصاب قبل البدء. ابحث عن أي مخاطر مثل الكهرباء أو حركة المرور.",
//       "voice": "تأكد أولاً من أمان الموقع قبل الاقتراب من المصاب",
//       "image": "assets/images/step1.png",
//     },
//     {
//       "title": "افحص الاستجابة",
//       "desc":
//           "هز كتفي المصاب وناده بصوت عالٍ: هل أنت بخير؟ ابحث عن أي حركة أو تنفس.",
//       "voice": "افحص استجابة المصاب، قم بهز كتفيه والمناداة عليه بصوت عال",
//       "image": "assets/images/step2.png",
//     },
//     {
//       "title": "اتصل بالإسعاف (997)",
//       "desc":
//           "إذا لم يستجب، اطلب المساعدة فوراً. اتصل بالرقم 997 وحدد موقعك بدقة.",
//       "voice": "المصاب لا يستجيب، اتصل بالإسعاف فوراً على الرقم تسعة تسعة سبعة",
//       "image": "assets/images/step3.png",
//     },
//     {
//       "title": "ابدأ ضغطات الصدر",
//       "desc":
//           "ضع كعب يدك في منتصف الصدر. اضغط بقوة وسرعة (100-120 ضغطة في الدقيقة).",
//       "voice": "ضع كعب يدك في منتصف الصدر، وابدأ بالضغط بقوة وسرعة",
//       "image": "assets/images/step4.png",
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initTts();
//   }

//   Future<void> _initTts() async {
//     // إعدادات الصوت للأوفلاين
//     await _tts.setLanguage("ar");
//     await _tts.setSpeechRate(0.5); // سرعة النطق
//     await _tts.setVolume(1.0); // أعلى مستوى صوت

//     // نطق الخطوة الأولى عند الدخول
//     _speakStep(0);
//   }

//   void _speakStep(int index) async {
//     await _tts.stop();
//     await _tts.speak(_cprSteps[index]['voice']!);
//   }

//   @override
//   void dispose() {
//     _tts.stop(); // إيقاف الصوت عند الخروج
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("دليل الإنعاش CPR"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           // شريط التقدم العلوي
//           LinearProgressIndicator(
//             value: (_currentStep + 1) / _cprSteps.length,
//             color: Colors.green,
//             backgroundColor: Colors.grey[200],
//           ),

//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // عرض الصورة المحلية
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [
//                           BoxShadow(color: Colors.black12, blurRadius: 10),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: Image.asset(
//                           _cprSteps[_currentStep]['image']!,
//                           fit: BoxFit.contain,
//                           // إذا الصورة مو موجودة بيطلع أيقونة بدل الخطأ
//                           errorBuilder: (context, error, stackTrace) =>
//                               const Icon(
//                                 Icons.medical_services,
//                                 size: 100,
//                                 color: Colors.red,
//                               ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),
//                   Text(
//                     _cprSteps[_currentStep]['title']!,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     _cprSteps[_currentStep]['desc']!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 18, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // أزرار التحكم
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
//             color: Colors.grey[100],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _currentStep > 0
//                     ? TextButton(
//                         onPressed: () {
//                           setState(() => _currentStep--);
//                           _speakStep(_currentStep);
//                         },
//                         child: const Text("السابق"),
//                       )
//                     : const SizedBox(width: 60),

//                 // زر إعادة الصوت
//                 FloatingActionButton(
//                   onPressed: () => _speakStep(_currentStep),
//                   backgroundColor: Colors.redAccent,
//                   child: const Icon(Icons.volume_up, color: Colors.white),
//                 ),

//                 ElevatedButton(
//                   onPressed: () {
//                     if (_currentStep < _cprSteps.length - 1) {
//                       setState(() => _currentStep++);
//                       _speakStep(_currentStep);
//                     } else {
//                       Navigator.pop(context);
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                   child: Text(
//                     _currentStep == _cprSteps.length - 1 ? "إنهاء" : "التالي",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

//الكود الافضل اللي استطعت جعل السواره الاتصال بها ناجح في الخلفيه
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
// import 'package:maps_launcher/maps_launcher.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';

// const MethodChannel platform = MethodChannel(
//   'com.example.heart_safe/emergency',
// );
// // مفتاح عالمي للتنقل بين الشاشات
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: initializationSettingsAndroid),
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     // داخل دالة main -> onDidReceiveNotificationResponse
//     onDidReceiveNotificationResponse: (NotificationResponse details) async {
//       // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
//       // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

//       // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
//       EmergencyController.isEmergencyActive = true;

//       // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
//       _handleEmergencyJump();
//     },
//   );

//   await initializeBackgroundService();
//   runApp(const HeartSafeApp());
// }

// // دالة مساعدة للقفز لصفحة الطوارئ
// void _handleEmergencyJump() {
//   EmergencyController.isEmergencyActive = true;
//   navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
//   );
// }

// // ================== محرك العمل في الخلفية ==================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'heart_safe_channel',
//     'Heart Safe Service',
//     description: 'يراقب السقوط في الخلفية',
//     importance: Importance.max, // تغيرت لضمان الصوت والقفزة
//     enableVibration: true,
//     playSound: true,
//     showBadge: true,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'heart_safe_channel',
//       initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
//       initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// // بث الموقع SOS عبر Nearby في الخلفية
// // دالة بث الموقع SOS في الخلفية
// void _startBackgroundSOS() async {
//   try {
//     Position pos = await Geolocator.getCurrentPosition();
//     await Nearby().startAdvertising(
//       "SOS_VICTIM",
//       Strategy.P2P_STAR,
//       onConnectionInitiated: (id, info) =>
//           Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
//       onConnectionResult: (id, status) {},
//       onDisconnected: (id) {},
//       serviceId: "com.example.heart_safe",
//     );
//     print(
//       "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
//     );
//   } catch (e) {
//     print("SOS Background Error: $e");
//   }
// }

// // دالة الاتصال بالسوارة في الخلفية
// void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//   ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   ble.FlutterBluePlus.scanResults.listen((results) async {
//     for (ble.ScanResult r in results) {
//       if (r.device.platformName.contains("HeartSafe")) {
//         ble.FlutterBluePlus.stopScan();
//         await r.device.connect();
//         var services = await r.device.discoverServices();
//         for (var s in services) {
//           if (s.uuid.toString().contains("180d")) {
//             for (var c in s.characteristics) {
//               if (c.uuid.toString().contains("2a37")) {
//                 await c.setNotifyValue(true);
//                 c.lastValueStream.listen((value) {
//                   // ✅ تم التصحيح: لا نستخدم setState هنا
//                   if (value.length > 1) {
//                     int currentBpm = value[1];
//                     // نرسل القيمة للدالة التي ستحدث الإشعار
//                     onBpmUpdate(currentBpm);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//   });
// }

// void _showNormalNotification() async {
//   final plugin = FlutterLocalNotificationsPlugin();
//   await plugin.cancel(911); // إغلاق إشعار الطوارئ
//   // إظهار إشعار الخدمة العادي
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'heart_safe_channel',
//     'Service',
//     importance: Importance.low,
//     priority: Priority.low,
//   );
//   await plugin.show(
//     100,
//     'الحارس الشخصي نشط 🛡️',
//     'أنا أراقب سلامتك الآن...',
//     const NotificationDetails(android: androidDetails),
//   );
// }

// // 🔥 النظام الكامل: منقذ بالخلفية + تحول لمصاب عند السقوط

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // 🛡️ متغيرات الحالة
//   bool isEmergencyMode = false;
//   int lastRecordedBpm = 0;
//   StreamSubscription? btSubscription;
//   bool isBroadcasting = false;
//   bool isRescuerMode = true; // 🔑 المفتاح: نبدأ كمنقذ دائماً

//   // ══════════════════════════════════════════════════════════
//   // 🟢 دالة تشغيل وضع المنقذ (Discovery - دائماً نشط)
//   // ══════════════════════════════════════════════════════════
//   Future<void> startRescuerMode() async {
//     if (isRescuerMode && !isEmergencyMode) return; // لو شغال، ما نعيد

//     try {
//       print("🔍 بدء وضع المنقذ في الخلفية...");

//       // إيقاف أي بث سابق (لو كنا مصابين)
//       await Nearby().stopAdvertising().catchError((e) => null);
//       await Nearby().stopDiscovery().catchError((e) => null);

//       bool started = await Nearby().startDiscovery(
//         "Guardian_${Random().nextInt(10000)}",
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           print("🚨 وجدت مصاب: $name");

//           if (name.startsWith("VICTIM_")) {
//             // 📢 إرسال إشعار فوري للمنقذ
//             _showRescuerAlert(id, name);

//             // طلب الاتصال لاستقبال البيانات
//             Nearby().requestConnection(
//               "Guardian",
//               id,
//               onConnectionInitiated: (id, info) {
//                 Nearby().acceptConnection(
//                   id,
//                   onPayLoadRecieved: (endId, payload) {
//                     if (payload.type == PayloadType.BYTES &&
//                         payload.bytes != null) {
//                       try {
//                         String jsonData = utf8.decode(payload.bytes!);
//                         Map<String, dynamic> victimData = jsonDecode(jsonData);

//                         print("📦 بيانات المصاب: $victimData");

//                         // إرسال للواجهة
//                         service.invoke('victimFound', {
//                           'id': id,
//                           'lat': victimData['lat'],
//                           'lng': victimData['lng'],
//                           'bpm': victimData['bpm'],
//                         });

//                         // تحديث الإشعار بالتفاصيل
//                         _showRescuerDetails(victimData);
//                       } catch (e) {
//                         print("❌ خطأ في فك البيانات: $e");
//                       }
//                     }
//                   },
//                 );
//               },
//               onConnectionResult: (id, status) {
//                 print("🔗 حالة الاتصال: $status");
//               },
//               onDisconnected: (id) {
//                 print("❌ انقطع الاتصال مع المصاب");
//               },
//             );
//           }
//         },
//         onEndpointLost: (id) {
//           print("📡 فُقد المصاب: $id");
//           service.invoke('victimLost', {'id': id});
//         },
//         serviceId: "com.example.heart_safe",
//       );

//       isRescuerMode = started;
//       print(started ? "✅ وضع المنقذ نشط" : "❌ فشل تشغيل وضع المنقذ");

//       if (service is AndroidServiceInstance && started) {
//         service.setForegroundNotificationInfo(
//           title: "🛡️ الحارس الشخصي نشط",
//           content: "وضع المنقذ: جاهز لاستقبال إشارات SOS",
//         );
//       }
//     } catch (e) {
//       print("❌ خطأ في وضع المنقذ: $e");
//     }
//   }

//   // ══════════════════════════════════════════════════════════
//   // 🔵 دالة الاتصال بالسوارة (عند السقوط فقط)
//   // ══════════════════════════════════════════════════════════
//   Future<void> startBackgroundBluetooth(Function(int) onBpmUpdate) async {
//     try {
//       print("🔍 بدء مسح السوارة...");

//       await ble.FlutterBluePlus.stopScan();
//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       btSubscription?.cancel(); // إلغاء أي اشتراك سابق
//       btSubscription = ble.FlutterBluePlus.scanResults.listen((results) async {
//         for (ble.ScanResult r in results) {
//           if (r.device.platformName.contains("HeartSafe")) {
//             await ble.FlutterBluePlus.stopScan();
//             print("✅ وجدت السوارة");

//             try {
//               await r.device.connect(timeout: const Duration(seconds: 10));
//               var services = await r.device.discoverServices();

//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) {
//                         if (value.length > 1 && isEmergencyMode) {
//                           // 🔑 فقط لو الطوارئ نشطة
//                           int currentBpm = value[1];
//                           print("💓 نبض: $currentBpm");
//                           onBpmUpdate(currentBpm);
//                         }
//                       });
//                       return;
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               print("❌ خطأ في الاتصال: $e");
//             }
//           }
//         }
//       });
//     } catch (e) {
//       print("❌ خطأ في البلوتوث: $e");
//     }
//   }

//   // ══════════════════════════════════════════════════════════
//   // 🔴 دالة بث SOS (عند السقوط فقط)
//   // ══════════════════════════════════════════════════════════
//   Future<void> startEmergencyBroadcast() async {
//     if (isBroadcasting) return;

//     try {
//       print("📍 جاري الحصول على الموقع...");

//       Position pos =
//           await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high,
//             timeLimit: const Duration(seconds: 15),
//           ).catchError((e) {
//             print("⚠️ فشل الموقع: $e");
//             return Position(
//               latitude: 0.0,
//               longitude: 0.0,
//               timestamp: DateTime.now(),
//               accuracy: 0.0,
//               altitude: 0.0,
//               altitudeAccuracy: 0.0,
//               heading: 0.0,
//               headingAccuracy: 0.0,
//               speed: 0.0,
//               speedAccuracy: 0.0,
//             );
//           });

//       if (pos.latitude == 0.0) {
//         print("❌ موقع غير صالح");
//         return;
//       }

//       print("✅ الموقع: ${pos.latitude}, ${pos.longitude}");

//       // 🔑 إيقاف وضع المنقذ والتحول لوضع المصاب
//       await Nearby().stopDiscovery();
//       isRescuerMode = false;

//       String victimName = "VICTIM_${Random().nextInt(10000)}";

//       bool started = await Nearby().startAdvertising(
//         victimName,
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           print("🤝 منقذ يحاول الاتصال: $id");
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               print("📨 رسالة من المنقذ");
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             print("✅ اتصال ناجح مع منقذ: $id");

//             String dataPackage = jsonEncode({
//               'lat': pos.latitude,
//               'lng': pos.longitude,
//               'bpm': lastRecordedBpm,
//               'emergency': true,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             print("📤 تم إرسال البيانات للمنقذ");

//             _showStaticEmergencyNotification(
//               lastBpm: lastRecordedBpm,
//               status: "✅ تم إرسال موقعك ونبضك للمنقذ!",
//             );
//           }
//         },
//         onDisconnected: (id) {
//           print("❌ انقطع المنقذ: $id");
//         },
//         serviceId: "com.example.heart_safe",
//       );

//       isBroadcasting = started;
//       print(started ? "✅ بدء البث" : "❌ فشل البث");
//     } catch (e) {
//       print("❌ خطأ في البث: $e");
//     }
//   }

//   // ══════════════════════════════════════════════════════════
//   // 🚨 مستمع السقوط (التحول من منقذ → مصاب)
//   // ══════════════════════════════════════════════════════════
//   userAccelerometerEvents.listen((event) async {
//     double acc = sqrt(
//       event.x * event.x + event.y * event.y + event.z * event.z,
//     );

//     if (acc > 32 && !isEmergencyMode) {
//       isEmergencyMode = true;
//       print("🚨🚨🚨 سقوط! التحول لوضع المصاب...");

//       // 1️⃣ إشعار فوري
//       service.invoke('triggerEmergency');
//       platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

//       _showStaticEmergencyNotification(
//         lastBpm: lastRecordedBpm,
//         status: "🚨 سقوط! جاري بث الموقع...",
//       );

//       // 2️⃣ بدء قراءة النبض
//       startBackgroundBluetooth((newBpm) {
//         lastRecordedBpm = newBpm;
//         service.invoke('updateBpmUi', {'bpm': newBpm});

//         _showStaticEmergencyNotification(
//           lastBpm: newBpm,
//           status: "💓 النبض: $newBpm BPM | جاري البث...",
//         );
//       });

//       // 3️⃣ بث SOS بعد ثانيتين
//       await Future.delayed(const Duration(seconds: 2));
//       startEmergencyBroadcast();
//     }
//   });

//   // ══════════════════════════════════════════════════════════
//   // ✅ مستمع "أنا بخير" (التصفير الكامل)
//   // ══════════════════════════════════════════════════════════
//   service.on('resetEmergency').listen((event) async {
//     print("⚡ تصفير: أنا بخير!");

//     // 🛑 إيقاف كل شيء
//     isEmergencyMode = false;
//     isBroadcasting = false;

//     btSubscription?.cancel();
//     btSubscription = null;

//     await ble.FlutterBluePlus.stopScan();
//     await Nearby().stopAdvertising();

//     // 🗑️ مسح إشعار الطوارئ
//     final plugin = FlutterLocalNotificationsPlugin();
//     await plugin.cancel(911);

//     // 🔄 العودة لوضع المنقذ
//     await Future.delayed(const Duration(seconds: 1));
//     startRescuerMode();

//     print("✅ تم التصفير والعودة لوضع المنقذ");
//   });

//   // ══════════════════════════════════════════════════════════
//   // 📊 مستمعات أخرى
//   // ══════════════════════════════════════════════════════════
//   service.on('checkStatus').listen((event) {
//     service.invoke('statusResponse', {'isActive': isEmergencyMode});
//   });

//   service.on('updateBpmData').listen((event) {
//     if (event != null && event['bpm'] != null) {
//       lastRecordedBpm = event['bpm'];
//       service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
//     }
//   });

//   // 🚀 الانطلاقة: تشغيل وضع المنقذ فوراً
//   startRescuerMode();

//   print("🎯 النظام جاهز: منقذ في الخلفية + جاهز للتحول لمصاب");
// }

// // ══════════════════════════════════════════════════════════
// // 📢 إشعار الطوارئ (للمصاب)
// // ══════════════════════════════════════════════════════════
// // Future<void> _showStaticEmergencyNotification({
// //   required int lastBpm,
// //   required String status,
// // }) async {
// //   final plugin = FlutterLocalNotificationsPlugin();

// //   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
// //     'emergency_alert',
// //     'Emergency Status',
// //     importance: Importance.max,
// //     priority: Priority.high,
// //     ongoing: true,
// //     color: const Color.fromARGB(255, 255, 0, 0),
// //     subText: "نظام الحماية نشط 🛡️",
// //   );

// //   await plugin.show(
// //     911,
// //     lastBpm > 0 ? '🚨 سقوط! النبض: $lastBpm BPM' : '🚨 تنبيه: تم رصد سقوط!',
// //     status,
// //     NotificationDetails(android: androidDetails),
// //   );
// // }

// // ══════════════════════════════════════════════════════════
// // 🚑 إشعار للمنقذ (اكتشاف مصاب)
// // ══════════════════════════════════════════════════════════
// Future<void> _showRescuerAlert(String victimId, String victimName) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'rescuer_alert',
//     'Victim Found',
//     importance: Importance.max,
//     priority: Priority.high,
//     color: const Color.fromARGB(255, 255, 165, 0),
//     enableVibration: true,
//     playSound: true,
//   );

//   await plugin.show(
//     victimId.hashCode,
//     '🚑 مصاب قريب منك!',
//     'شخص يحتاج مساعدة عاجلة - اضغط لعرض التفاصيل',
//     NotificationDetails(android: androidDetails),
//     payload: 'victim_$victimId',
//   );
// }

// // ══════════════════════════════════════════════════════════
// // 📍 إشعار تفاصيل المصاب (مع الموقع والنبض)
// // ══════════════════════════════════════════════════════════
// Future<void> _showRescuerDetails(Map<String, dynamic> victimData) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   double lat = victimData['lat'];
//   double lng = victimData['lng'];
//   int bpm = victimData['bpm'] ?? 0;

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'victim_details',
//     'Victim Details',
//     importance: Importance.max,
//     priority: Priority.high,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     styleInformation: BigTextStyleInformation(
//       'النبض: $bpm BPM\nالموقع: $lat, $lng\n\nاضغط لفتح الخريطة',
//     ),
//   );

//   await plugin.show(
//     999,
//     '📍 بيانات المصاب',
//     'النبض: $bpm BPM | اضغط للتوجه',
//     NotificationDetails(android: androidDetails),
//     payload: 'map_$lat,$lng',
//   );
// }
// // ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// // لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// // دالة تشغيل الرادار بأمان
// void _runRadarSystem(ServiceInstance service) {
//   try {
//     Nearby().stopAdvertising();
//     Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.contains("VICTIM")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//   } catch (e) {}
// }

// // دالة تشغيل الرادار المحمية
// void _safeStartRadar(ServiceInstance service) async {
//   try {
//     await Nearby().stopAdvertising();
//     await Nearby().startDiscovery(
//       "Guardian",
//       Strategy.P2P_CLUSTER,
//       onEndpointFound: (id, name, sid) {
//         if (name.startsWith("VICTIM|")) {
//           service.invoke('victimFound', {'id': id, 'name': name});
//         }
//       },
//       onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
//       serviceId: "com.example.heart_safe",
//     );
//     print("📡 الرادار يعمل الآن بصمت في الخلفية...");
//   } catch (e) {
//     print("Radar Error: $e");
//   }
// }
// // ---------------------------------------------------------
// // الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// // ---------------------------------------------------------

// // دالة تحديث الإشعار بالنبض الحي
// // دالة تحديث الإشعار مع إضافة زر التفاعل
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     onlyAlertOnce: false,
//     showWhen: true,
//     usesChronometer: false,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   // 🚀 التعديل الجوهري هنا:
//   // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
//   await plugin.show(
//     911,
//     lastBpm > 0
//         ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
//         : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// Future<void> _showEmergencyNotification() async {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
//   final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

//   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
//     'Emergency Notification',
//     importance: Importance.max,
//     priority: Priority.high,

//     // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
//     fullScreenIntent: true,

//     // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
//     category: AndroidNotificationCategory.alarm,
//     audioAttributesUsage: AudioAttributesUsage.alarm,

//     // 🛡️ ضمان الظهور فوق قفل الشاشة
//     visibility: NotificationVisibility.public,

//     // 🔊 تنبيهات إضافية لضمان الاستيقاظ
//     ongoing: true, // يمنع المستخدم من حذفه بسهولة
//     vibrationPattern: vibrationPattern,
//     enableLights: true,
//     color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
//     ledColor: const Color.fromARGB(255, 255, 0, 0),
//     ledOnMs: 1000,
//     ledOffMs: 500,

//     // نص يظهر في شريط الحالة فور الصدمة
//     ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
//   );

//   await flutterLocalNotificationsPlugin.show(
//     911,
//     '🚨 حالة طوارئ: تم رصد سقوط!',
//     'جاري فحص النبض وبث الموقع للمنقذين...',
//     NotificationDetails(android: androidDetails),
//     payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
//   );
// }
// // ================== واجهات التطبيق ==================

// class HeartSafeApp extends StatelessWidget {
//   const HeartSafeApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Heart Safe',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//     );
//   }
// }

// class EmergencyController {
//   static bool isEmergencyActive = false;
//   static int currentBpm = 0;
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppPermissions();
//     // 🕵️ الاستجواب الفوري عند فتح التطبيق
//     _checkBackgroundEmergencyStatus();
//   }

//   void _checkBackgroundEmergencyStatus() {
//     // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
//     FlutterBackgroundService().invoke('checkStatus');

//     FlutterBackgroundService().on('statusResponse').listen((event) {
//       if (event != null && event['isActive'] == true) {
//         // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
//         if (!EmergencyController.isEmergencyActive) {
//           _handleEmergencyJump();
//         }
//       }
//     });
//   }

//   void _requestPermissions() async {
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.nearbyWifiDevices,
//       Permission.sensors,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();
//   }

//   // 🛠️ دالة تجميع كل التصاريح في مكان واحد
//   Future<void> _initializeAppPermissions() async {
//     // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
//     await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.sensors,
//     ].request();

//     // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
//     // هذا هو الكود الذي سألته عنه
//     if (await Permission.systemAlertWindow.isDenied) {
//       // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
//       _showPermissionDialog();
//     }
//   }

//   // دالة طلب تصريح Overlay (التي سألت عنها)
//   Future<void> _requestOverlayPermission() async {
//     await Permission.systemAlertWindow.request();
//   }

//   // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("🛡️ تفعيل الحماية القصوى"),
//         content: const Text(
//           "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _requestOverlayPermission(); // نقل المستخدم للإعدادات
//             },
//             child: const Text("حسناً، تفعيل"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Heart Safe 🫀',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildStatusCard(),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               padding: const EdgeInsets.all(20),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               children: [
//                 _buildBtn(
//                   context,
//                   Icons.monitor_heart,
//                   'فحص النبض',
//                   Colors.pink,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HeartRatePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.radar,
//                   'وضع المنقذ',
//                   Colors.green,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const BroadcastPage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.medical_services,
//                   'دليل الإنعاش',
//                   Colors.blue,
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CprGuidePage(),
//                     ),
//                   ),
//                 ),
//                 _buildBtn(
//                   context,
//                   Icons.info,
//                   'حول التطبيق',
//                   Colors.orange,
//                   () {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.security, color: Colors.green, size: 40),
//           SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "الحارس الشخصي نشط",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "نظام رصد السقوط يعمل الآن",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBtn(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.5), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 50, color: color),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة الطوارئ الآلية ==================
// // ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

// class AutomaticEmergencyPage extends StatefulWidget {
//   const AutomaticEmergencyPage({super.key});

//   @override
//   State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
// }

// class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
//   int bpm = 0;
//   String statusMessage = "🚨 جاري بدء رصد النبض..."; // ← تغيير الاسم
//   bool isConnected = false;
//   StreamSubscription? _scanSubscription;

//   // معرف فريد للضحية
//   final String myUserName = "Emergency_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";
//   bool isBroadcasting = false;

//   @override
//   void initState() {
//     super.initState();
//     // بدء الإجراءات الطارئة بالترتيب
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _startEmergencyProtocol();
//     });
//   }

//   // 🚨 بروتوكول الطوارئ الكامل
//   void _startEmergencyProtocol() async {
//     // 1️⃣ بدء قراءة النبض
//     _forcePulseCheck();

//     // 2️⃣ الانتظار قليلاً لضمان الحصول على موقع دقيق
//     await Future.delayed(const Duration(seconds: 5));

//     // 3️⃣ بث الاستغاثة بالتقنية المتطورة
//     _broadcastSOSAdvanced();
//   }

//   // 🛠️ قراءة النبض من السوارة (نفس الكود الناجح)
//   void _forcePulseCheck() async {
//     try {
//       await ble.FlutterBluePlus.stopScan();

//       var state = await ble.FlutterBluePlus.adapterState.first;
//       if (state != ble.BluetoothAdapterState.on) {
//         setState(() => statusMessage = "⚠️ يرجى تفعيل البلوتوث فوراً!");
//         return;
//       }

//       setState(() => statusMessage = "🔍 جاري رصد السوارة الآن...");

//       await ble.FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 20),
//         androidUsesFineLocation: true,
//       );

//       _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
//         results,
//       ) async {
//         for (ble.ScanResult r in results) {
//           if (r.device.platformName.contains("HeartSafe") && !isConnected) {
//             isConnected = true;
//             await ble.FlutterBluePlus.stopScan();

//             setState(() => statusMessage = "✅ تم الربط! جاري قراءة النبض...");

//             try {
//               await r.device.connect(timeout: const Duration(seconds: 10));

//               var services = await r.device.discoverServices();
//               for (var s in services) {
//                 if (s.uuid.toString().contains("180d")) {
//                   for (var c in s.characteristics) {
//                     if (c.uuid.toString().contains("2a37")) {
//                       await c.setNotifyValue(true);
//                       c.lastValueStream.listen((value) async {
//                         if (value.length > 1 && mounted) {
//                           int newBpm = value[1];
//                           setState(() {
//                             bpm = newBpm;
//                             statusMessage =
//                                 "🚨 يتم بث نبضك ($bpm BPM) وموقعك للمنقذين";
//                           });

//                           // حفظ النبض في SharedPreferences
//                           final prefs = await SharedPreferences.getInstance();
//                           await prefs.setInt('last_bpm', newBpm);

//                           // مزامنة مع الخدمة الخلفية
//                           FlutterBackgroundService().invoke('updateBpmData', {
//                             'bpm': newBpm,
//                           });

//                           debugPrint("💾 Emergency BPM saved: $newBpm");
//                         }
//                       });
//                     }
//                   }
//                 }
//               }
//             } catch (e) {
//               isConnected = false;
//               debugPrint("❌ Connection error: $e");
//               // إعادة محاولة بعد 3 ثواني
//               Future.delayed(const Duration(seconds: 3), _forcePulseCheck);
//             }
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("❌ BT Error: $e");
//     }
//   }

//   // 🚨 بث الاستغاثة بالتقنية المتطورة (Payload-based)
//   void _broadcastSOSAdvanced() async {
//     if (isBroadcasting) return; // منع البث المزدوج

//     try {
//       // إيقاف أي بث سابق
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();

//       setState(() => statusMessage = "📍 جاري تحديد موقعك...");

//       // الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       debugPrint(
//         "📍 Location obtained: ${currentPos.latitude}, ${currentPos.longitude}",
//       );

//       // جلب آخر نبض محفوظ
//       int lastBpm = bpm;
//       if (lastBpm == 0) {
//         try {
//           final prefs = await SharedPreferences.getInstance();
//           lastBpm = prefs.getInt('last_bpm') ?? 72;
//         } catch (e) {
//           lastBpm = 72;
//         }
//       }

//       debugPrint("🚨 Starting SOS broadcast with BPM: $lastBpm");

//       // بدء البث باسم بسيط
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Emergency: Connection initiated with rescuer: $id");

//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               debugPrint("📨 Received message from rescuer");
//             },
//           );
//         },
//         onConnectionResult: (id, connectionStatus) async {
//           if (connectionStatus == Status.CONNECTED) {
//             debugPrint("✅ Emergency: Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'emergency': true, // علامة أن هذه حالة طوارئ
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "✅ تم إرسال بياناتك للمنقذ!");
//             }

//             debugPrint("📡 Emergency data sent successfully");
//           } else {
//             debugPrint("❌ Connection failed with rescuer: $id");
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Rescuer disconnected: $id");
//           if (mounted) {
//             setState(
//               () => statusMessage = "⚠️ انقطع الاتصال - جاري إعادة البث...",
//             );
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isBroadcasting = started;
//         if (started) {
//           statusMessage = "📡 يتم بث موقعك ونبضك ($lastBpm BPM) للمنقذين...";
//         } else {
//           statusMessage = "❌ فشل البث - جاري إعادة المحاولة...";
//           // إعادة المحاولة بعد 3 ثواني
//           Future.delayed(const Duration(seconds: 3), _broadcastSOSAdvanced);
//         }
//       });

//       debugPrint(
//         started
//             ? "✅ SOS broadcast started successfully"
//             : "❌ SOS broadcast failed",
//       );
//     } catch (e) {
//       debugPrint("❌ Broadcast error: $e");
//       setState(() => statusMessage = "❌ خطأ في البث - جاري إعادة المحاولة...");

//       // إعادة المحاولة بعد 5 ثواني
//       Future.delayed(const Duration(seconds: 5), _broadcastSOSAdvanced);
//     }
//   }

//   // إيقاف كل شيء عند الخروج
//   void _stopEmergency() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopAllEndpoints();
//       await ble.FlutterBluePlus.stopScan();
//       _scanSubscription?.cancel();

//       FlutterBackgroundService().invoke('resetEmergency');

//       if (mounted) {
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       debugPrint("❌ Stop error: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     ble.FlutterBluePlus.stopScan();
//     Nearby().stopAdvertising();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[900],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // أيقونة التحذير
//                   const Icon(
//                     Icons.warning_rounded,
//                     size: 100,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(height: 20),

//                   // العنوان
//                   const Text(
//                     "🚨 حالة طوارئ",
//                     style: TextStyle(
//                       fontSize: 32,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),

//                   const Text(
//                     "تم رصد سقوط عنيف",
//                     style: TextStyle(fontSize: 18, color: Colors.white70),
//                   ),
//                   const SizedBox(height: 30),

//                   // رسالة الحالة
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(color: Colors.white30),
//                     ),
//                     child: Text(
//                       statusMessage,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // عرض النبض
//                   Container(
//                     padding: const EdgeInsets.all(40),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           bpm > 0 ? "$bpm" : "--",
//                           style: TextStyle(
//                             fontSize: 70,
//                             color: Colors.red[900],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           "BPM",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.red[700],
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // مؤشر البث
//                   if (isBroadcasting)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.wifi_tethering,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "البث نشط",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 30),

//                   // زر الإيقاف
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.red[900],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 18,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 8,
//                     ),
//                     icon: const Icon(Icons.check_circle, size: 28),
//                     onPressed: _stopEmergency,
//                     label: const Text(
//                       "أنا بخير - إيقاف الطوارئ",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // معلومات إضافية
//                   Text(
//                     "يتم بث موقعك تلقائياً للمنقذين القريبين",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================== صفحة المنقذ (الرادار) ==================

// class BroadcastPage extends StatefulWidget {
//   const BroadcastPage({super.key});

//   @override
//   State<BroadcastPage> createState() => _BroadcastPageState();
// }

// class _BroadcastPageState extends State<BroadcastPage> {
//   bool isVictimMode = false;
//   bool isRescuerMode = false;
//   String statusMessage = "مختبر البيانات الطبية والمسافة";

//   Map<String, Map<String, dynamic>> foundVictims = {};
//   StreamSubscription? _positionStream;
//   int _currentBpm = 0; // ← تخزين النبض محلياً

//   // معرف فريد للمستخدم
//   final String myUserName = "User_${Random().nextInt(10000)}";
//   final String serviceId = "com.example.heart_safe";

//   @override
//   void initState() {
//     super.initState();
//     _requestAllPermissions();
//     _loadLastBpm(); // ← تحميل آخر نبض مسجل
//   }

//   // تحميل آخر قيمة نبض من EmergencyController
//   void _loadLastBpm() {
//     setState(() {
//       _currentBpm = EmergencyController.currentBpm;
//       // إذا كانت القيمة 0، نستخدم قيمة افتراضية معقولة
//       if (_currentBpm == 0) {
//         _currentBpm = 72; // معدل نبض طبيعي افتراضي
//       }
//     });
//     debugPrint("📊 Current BPM loaded: $_currentBpm");
//   }

//   // طلب جميع الأذونات عند بدء الصفحة
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.location,
//         Permission.locationAlways,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//         Permission.nearbyWifiDevices,
//       ].request();
//     }
//   }

//   // 🛠️ دالة التصفير الصلب
//   Future<void> _prepareRadio() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Nearby().stopAllEndpoints();
//       _positionStream?.cancel();
//       if (mounted) {
//         setState(() => foundVictims.clear());
//       }
//     } catch (e) {
//       debugPrint("Cleanup Error: $e");
//     }
//   }

//   // ================== وضع الضحية (Victim Mode) ==================
//   void _toggleVictimMode() async {
//     await _prepareRadio();

//     if (isVictimMode) {
//       setState(() {
//         isVictimMode = false;
//         statusMessage = "توقف البث";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

//     try {
//       // 1. فحص تفعيل الموقع
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
//         return;
//       }

//       // 2. الحصول على الموقع الحالي
//       Position currentPos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 15),
//       );

//       setState(() => statusMessage = "⏳ جاري بدء البث...");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       // 3. جلب آخر نبض محفوظ من SharedPreferences (نفس اللي يستخدمه كود السقوط)
//       int lastBpm = 0;
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         lastBpm = prefs.getInt('last_bpm') ?? 0;

//         // إذا ما لقينا قيمة محفوظة، نحاول من EmergencyController
//         if (lastBpm == 0) {
//           lastBpm = EmergencyController.currentBpm;
//         }

//         // إذا ما زال 0، نستخدم قيمة افتراضية
//         if (lastBpm == 0) {
//           lastBpm = 72; // معدل نبض طبيعي افتراضي
//         }
//       } catch (e) {
//         debugPrint("⚠️ Error loading BPM: $e");
//         lastBpm = EmergencyController.currentBpm > 0
//             ? EmergencyController.currentBpm
//             : 72;
//       }

//       debugPrint("📡 Broadcasting with BPM: $lastBpm (from SharedPreferences)");

//       // 4. بدء البث باسم بسيط (بدون إحداثيات)
//       bool started = await Nearby().startAdvertising(
//         "VICTIM_$myUserName", // اسم بسيط وقصير
//         Strategy.P2P_STAR,
//         onConnectionInitiated: (id, info) {
//           debugPrint("🤝 Connection initiated with: $id");
//           // قبول الاتصال فوراً
//           Nearby().acceptConnection(
//             id,
//             onPayLoadRecieved: (endId, payload) {
//               // يمكن استقبال رسائل من المنقذ هنا (اختياري)
//             },
//           );
//         },
//         onConnectionResult: (id, status) async {
//           if (status == Status.CONNECTED) {
//             debugPrint("✅ Connected to rescuer: $id");

//             // إرسال البيانات الطبية والموقع عبر Payload
//             String dataPackage = jsonEncode({
//               'lat': currentPos.latitude,
//               'lng': currentPos.longitude,
//               'bpm': lastBpm,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//             });

//             await Nearby().sendBytesPayload(
//               id,
//               Uint8List.fromList(utf8.encode(dataPackage)),
//             );

//             if (mounted) {
//               setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
//             }
//           }
//         },
//         onDisconnected: (id) {
//           debugPrint("❌ Disconnected from: $id");
//           if (mounted) {
//             setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isVictimMode = started;
//         isRescuerMode = false;
//         statusMessage = started
//             ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
//             : "❌ فشل البث - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
//       } else if (e.toString().contains('location')) {
//         errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Victim Mode Error: $e");
//     }
//   }

//   // ================== وضع المنقذ (Rescuer Mode) ==================
//   void _toggleRescuerMode() async {
//     await _prepareRadio();

//     if (isRescuerMode) {
//       setState(() {
//         isRescuerMode = false;
//         statusMessage = "توقف الرادار";
//       });
//       return;
//     }

//     // فحص الأذونات أولاً
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     // التحقق من منح جميع الأذونات
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
//       return;
//     }

//     setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
//     await Future.delayed(const Duration(milliseconds: 1500));

//     try {
//       bool started = await Nearby().startDiscovery(
//         myUserName,
//         Strategy.P2P_STAR,
//         onEndpointFound: (id, name, sid) {
//           debugPrint("🔍 Found endpoint: $name (ID: $id)");

//           // التحقق من أن الاسم يبدأ بـ VICTIM
//           if (!name.startsWith("VICTIM_")) return;

//           // طلب الاتصال فوراً (المفتاح الأساسي!)
//           Nearby().requestConnection(
//             myUserName,
//             id,
//             onConnectionInitiated: (id, info) {
//               debugPrint("🤝 Connection initiated with: $id");

//               // قبول الاتصال واستقبال البيانات
//               Nearby().acceptConnection(
//                 id,
//                 onPayLoadRecieved: (endId, payload) async {
//                   if (payload.type == PayloadType.BYTES &&
//                       payload.bytes != null) {
//                     try {
//                       // فك تشفير البيانات
//                       String jsonData = utf8.decode(payload.bytes!);
//                       Map<String, dynamic> victimData = jsonDecode(jsonData);

//                       double vLat = victimData['lat'];
//                       double vLng = victimData['lng'];
//                       int vBpm = victimData['bpm'] ?? 0;

//                       // حساب المسافة الأولية
//                       Position myPos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       double dist = Geolocator.distanceBetween(
//                         myPos.latitude,
//                         myPos.longitude,
//                         vLat,
//                         vLng,
//                       );

//                       // حفظ بيانات الضحية
//                       if (mounted) {
//                         setState(() {
//                           foundVictims[id] = {
//                             'distance': dist,
//                             'lat': vLat,
//                             'lng': vLng,
//                             'bpm': vBpm,
//                             'name': name,
//                           };
//                         });
//                       }

//                       // بدء تتبع المسافة الحية
//                       _startLiveTracking(id, vLat, vLng);

//                       debugPrint(
//                         "✅ Victim data received: ${victimData.toString()}",
//                       );
//                     } catch (e) {
//                       debugPrint("❌ Error parsing victim data: $e");
//                     }
//                   }
//                 },
//               );
//             },
//             onConnectionResult: (id, status) {
//               if (status == Status.CONNECTED) {
//                 debugPrint("✅ Successfully connected to victim: $id");
//               } else {
//                 debugPrint("❌ Connection failed with: $id");
//               }
//             },
//             onDisconnected: (id) {
//               debugPrint("❌ Victim disconnected: $id");
//               if (mounted) {
//                 setState(() => foundVictims.remove(id));
//               }
//             },
//           );
//         },
//         onEndpointLost: (id) {
//           debugPrint("📡 Endpoint lost: $id");
//           if (mounted) {
//             setState(() => foundVictims.remove(id));
//           }
//         },
//         serviceId: serviceId,
//       );

//       setState(() {
//         isRescuerMode = started;
//         isVictimMode = false;
//         statusMessage = started
//             ? "🔍 الرادار يستقبل البيانات الطبية..."
//             : "❌ فشل الرادار - أعد المحاولة";
//       });
//     } catch (e) {
//       String errorMsg;
//       if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
//         errorMsg =
//             "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
//       } else if (e.toString().contains('BLUETOOTH')) {
//         errorMsg = "❌ فعّل Bluetooth و WiFi";
//       } else {
//         errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
//       }
//       setState(() => statusMessage = errorMsg);
//       debugPrint("🔴 Rescuer Mode Error: $e");
//     }
//   }

//   // ================== تتبع المسافة الحية ==================
//   void _startLiveTracking(String victimId, double vLat, double vLng) {
//     _positionStream?.cancel();
//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.high,
//             distanceFilter: 1, // تحديث كل متر
//           ),
//         ).listen((myPos) {
//           if (mounted && foundVictims.containsKey(victimId)) {
//             double newDist = Geolocator.distanceBetween(
//               myPos.latitude,
//               myPos.longitude,
//               vLat,
//               vLng,
//             );
//             setState(() {
//               foundVictims[victimId]!['distance'] = newDist;
//             });
//           }
//         });
//   }

//   // ================== واجهة المستخدم ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("رادار المسافة والنبض"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           _buildTestConsole(),
//           Expanded(
//             child: foundVictims.isEmpty
//                 ? _buildEmptyState()
//                 : _buildVictimsList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestConsole() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             statusMessage,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 15),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _modeButton(
//                 "بث ضحية",
//                 Icons.wifi_tethering,
//                 isVictimMode,
//                 Colors.red,
//                 _toggleVictimMode,
//               ),
//               _modeButton(
//                 "رادار منقذ",
//                 Icons.radar,
//                 isRescuerMode,
//                 Colors.green,
//                 _toggleRescuerMode,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _modeButton(
//     String label,
//     IconData icon,
//     bool isActive,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(isActive ? Icons.stop : icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive ? Colors.black87 : color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildVictimsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(15),
//       itemCount: foundVictims.length,
//       itemBuilder: (context, index) {
//         String id = foundVictims.keys.elementAt(index);
//         var data = foundVictims[id]!;
//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 5,
//           margin: const EdgeInsets.only(bottom: 15),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "الحالة الحيوية:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "${data['bpm']} BPM",
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 30),
//                 Text(
//                   "${data['distance'].toStringAsFixed(1)} m",
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const Text(
//                   "المسافة للوصول",
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
//                     const SizedBox(width: 5),
//                     Text(
//                       "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
//                       style: TextStyle(fontSize: 11, color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isRescuerMode ? Icons.radar : Icons.info_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             isRescuerMode
//                 ? "جاري البحث عن ضحايا..."
//                 : "لا توجد إشارات نشطة حالياً",
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _prepareRadio();
//     super.dispose();
//   }
// }

// class HeartRatePage extends StatefulWidget {
//   const HeartRatePage({super.key});

//   @override
//   State<HeartRatePage> createState() => _HeartRatePageState();
// }

// class _HeartRatePageState extends State<HeartRatePage> {
//   int bpm = 0; // القيمة الحالية للنبض
//   bool isConnecting = false;
//   String statusMessage = "اضغط على الزر لبدء الفحص";

//   // دالة البحث والاتصال بالسوارة
//   void _startPulseCheck() async {
//     setState(() {
//       isConnecting = true;
//       statusMessage = "جاري البحث عن السوارة...";
//     });

//     // بدء مسح البلوتوث لمدة 10 ثوانٍ
//     ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

//     ble.FlutterBluePlus.scanResults.listen((results) async {
//       for (ble.ScanResult r in results) {
//         // البحث عن السوارة بالاسم المبرمج
//         if (r.device.platformName.contains("HeartSafe")) {
//           ble.FlutterBluePlus.stopScan();
//           setState(
//             () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
//           );

//           try {
//             await r.device.connect();
//             var services = await r.device.discoverServices();
//             for (var s in services) {
//               if (s.uuid.toString().contains("180d")) {
//                 // خدمة نبض القلب
//                 for (var c in s.characteristics) {
//                   if (c.uuid.toString().contains("2a37")) {
//                     // خاصية القياس
//                     await c.setNotifyValue(true);
//                     c.lastValueStream.listen((value) {
//                       if (value.length > 1 && mounted) {
//                         setState(() {
//                           bpm = value[1]; // تحديث رقم النبض على الشاشة
//                           isConnecting = false;
//                           statusMessage = "النبض مستقر الآن";
//                         });
//                       }
//                     });
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("فحص نبض القلب 💓"),
//         backgroundColor: Colors.pinkAccent,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // أيقونة القلب النابض
//             Icon(
//               Icons.favorite,
//               size: 150,
//               color: bpm > 0 ? Colors.red : Colors.grey[300],
//             ),
//             const SizedBox(height: 20),

//             // عرض رقم النبض
//             Text(
//               bpm > 0 ? "$bpm" : "--",
//               style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
//             ),
//             const Text(
//               "نبضة في الدقيقة (BPM)",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),

//             const SizedBox(height: 40),

//             // رسالة الحالة
//             Text(
//               statusMessage,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),

//             const SizedBox(height: 60),

//             // زر بدء الفحص اليدوي
//             ElevatedButton.icon(
//               onPressed: isConnecting ? null : _startPulseCheck,
//               icon: const Icon(Icons.bluetooth_searching),
//               label: Text(
//                 isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 30,
//                   vertical: 15,
//                 ),
//                 backgroundColor: Colors.pinkAccent,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CprGuidePage extends StatefulWidget {
//   const CprGuidePage({super.key});

//   @override
//   State<CprGuidePage> createState() => _CprGuidePageState();
// }

// class _CprGuidePageState extends State<CprGuidePage> {
//   final FlutterTts _tts = FlutterTts();
//   int _currentStep = 0;

//   // قائمة الخطوات باستخدام الصور المحلية (التي أضفتها في الـ assets)
//   final List<Map<String, String>> _cprSteps = [
//     {
//       "title": "تأكد من الأمان",
//       "desc":
//           "تأكد أن المكان آمن لك وللمصاب قبل البدء. ابحث عن أي مخاطر مثل الكهرباء أو حركة المرور.",
//       "voice": "تأكد أولاً من أمان الموقع قبل الاقتراب من المصاب",
//       "image": "assets/images/step1.png",
//     },
//     {
//       "title": "افحص الاستجابة",
//       "desc":
//           "هز كتفي المصاب وناده بصوت عالٍ: هل أنت بخير؟ ابحث عن أي حركة أو تنفس.",
//       "voice": "افحص استجابة المصاب، قم بهز كتفيه والمناداة عليه بصوت عال",
//       "image": "assets/images/step2.png",
//     },
//     {
//       "title": "اتصل بالإسعاف (997)",
//       "desc":
//           "إذا لم يستجب، اطلب المساعدة فوراً. اتصل بالرقم 997 وحدد موقعك بدقة.",
//       "voice": "المصاب لا يستجيب، اتصل بالإسعاف فوراً على الرقم تسعة تسعة سبعة",
//       "image": "assets/images/step3.png",
//     },
//     {
//       "title": "ابدأ ضغطات الصدر",
//       "desc":
//           "ضع كعب يدك في منتصف الصدر. اضغط بقوة وسرعة (100-120 ضغطة في الدقيقة).",
//       "voice": "ضع كعب يدك في منتصف الصدر، وابدأ بالضغط بقوة وسرعة",
//       "image": "assets/images/step4.png",
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initTts();
//   }

//   Future<void> _initTts() async {
//     // إعدادات الصوت للأوفلاين
//     await _tts.setLanguage("ar");
//     await _tts.setSpeechRate(0.5); // سرعة النطق
//     await _tts.setVolume(1.0); // أعلى مستوى صوت

//     // نطق الخطوة الأولى عند الدخول
//     _speakStep(0);
//   }

//   void _speakStep(int index) async {
//     await _tts.stop();
//     await _tts.speak(_cprSteps[index]['voice']!);
//   }

//   @override
//   void dispose() {
//     _tts.stop(); // إيقاف الصوت عند الخروج
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("دليل الإنعاش CPR"),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Column(
//         children: [
//           // شريط التقدم العلوي
//           LinearProgressIndicator(
//             value: (_currentStep + 1) / _cprSteps.length,
//             color: Colors.green,
//             backgroundColor: Colors.grey[200],
//           ),

//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // عرض الصورة المحلية
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [
//                           BoxShadow(color: Colors.black12, blurRadius: 10),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: Image.asset(
//                           _cprSteps[_currentStep]['image']!,
//                           fit: BoxFit.contain,
//                           // إذا الصورة مو موجودة بيطلع أيقونة بدل الخطأ
//                           errorBuilder: (context, error, stackTrace) =>
//                               const Icon(
//                                 Icons.medical_services,
//                                 size: 100,
//                                 color: Colors.red,
//                               ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),
//                   Text(
//                     _cprSteps[_currentStep]['title']!,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     _cprSteps[_currentStep]['desc']!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 18, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // أزرار التحكم
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
//             color: Colors.grey[100],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _currentStep > 0
//                     ? TextButton(
//                         onPressed: () {
//                           setState(() => _currentStep--);
//                           _speakStep(_currentStep);
//                         },
//                         child: const Text("السابق"),
//                       )
//                     : const SizedBox(width: 60),

//                 // زر إعادة الصوت
//                 FloatingActionButton(
//                   onPressed: () => _speakStep(_currentStep),
//                   backgroundColor: Colors.redAccent,
//                   child: const Icon(Icons.volume_up, color: Colors.white),
//                 ),

//                 ElevatedButton(
//                   onPressed: () {
//                     if (_currentStep < _cprSteps.length - 1) {
//                       setState(() => _currentStep++);
//                       _speakStep(_currentStep);
//                     } else {
//                       Navigator.pop(context);
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                   child: Text(
//                     _currentStep == _cprSteps.length - 1 ? "إنهاء" : "التالي",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart'; // 👈 ضروري جداً لعمل الـ MethodChannel
import 'package:maps_launcher/maps_launcher.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:nearby_connections/nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

const MethodChannel platform = MethodChannel(
  'com.example.heart_safe/emergency',
);
// مفتاح عالمي للتنقل بين الشاشات
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
    // داخل دالة main -> onDidReceiveNotificationResponse
    // داخل دالة main -> onDidReceiveNotificationResponse
    // داخل دالة main -> onDidReceiveNotificationResponse
    // داخل دالة main -> onDidReceiveNotificationResponse
    onDidReceiveNotificationResponse: (NotificationResponse details) async {
      // 🛡️ لم يعد هناك 'stop_emergency' من الخارج.
      // الضغط على أي جزء في الإشعار سيقوم بفتح التطبيق فوراً.

      // تفعيل حالة الطوارئ في الواجهة لضمان القفزة الصحيحة
      EmergencyController.isEmergencyActive = true;

      // القفز لصفحة الطوارئ (التي تحتوي على زر "أنا بخير" الحقيقي)
      _handleEmergencyJump();
    },
  );

  await initializeBackgroundService();
  runApp(const HeartSafeApp());
}

// دالة مساعدة للقفز لصفحة الطوارئ
void _handleEmergencyJump() {
  EmergencyController.isEmergencyActive = true;
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => const AutomaticEmergencyPage()),
  );
}

// ================== محرك العمل في الخلفية ==================
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // 👈 ضبط القناة لتكون Importance.max لضمان القفز على الشاشة
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'heart_safe_channel',
    'Heart Safe Service',
    description: 'يراقب السقوط في الخلفية',
    importance: Importance.max, // تغيرت لضمان الصوت والقفزة
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'heart_safe_channel',
      initialNotificationTitle: 'الحارس الشخصي نشط 🛡️',
      initialNotificationContent: 'جيش المنقذين يراقب سلامتك الآن...',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// بث الموقع SOS عبر Nearby في الخلفية
// دالة بث الموقع SOS في الخلفية
void _startBackgroundSOS() async {
  try {
    Position pos = await Geolocator.getCurrentPosition();
    await Nearby().startAdvertising(
      "SOS_VICTIM",
      Strategy.P2P_STAR,
      onConnectionInitiated: (id, info) =>
          Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {}),
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
      serviceId: "com.example.heart_safe",
    );
    print(
      "📡 SOS Advertising started in background at ${pos.latitude}, ${pos.longitude}",
    );
  } catch (e) {
    print("SOS Background Error: $e");
  }
}

// دالة الاتصال بالسوارة في الخلفية
void _startBackgroundBluetooth(Function(int) onBpmUpdate) async {
  ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  ble.FlutterBluePlus.scanResults.listen((results) async {
    for (ble.ScanResult r in results) {
      if (r.device.platformName.contains("HeartSafe")) {
        ble.FlutterBluePlus.stopScan();
        await r.device.connect();
        var services = await r.device.discoverServices();
        for (var s in services) {
          if (s.uuid.toString().contains("180d")) {
            for (var c in s.characteristics) {
              if (c.uuid.toString().contains("2a37")) {
                await c.setNotifyValue(true);
                c.lastValueStream.listen((value) {
                  // ✅ تم التصحيح: لا نستخدم setState هنا
                  if (value.length > 1) {
                    int currentBpm = value[1];
                    // نرسل القيمة للدالة التي ستحدث الإشعار
                    onBpmUpdate(currentBpm);
                  }
                });
              }
            }
          }
        }
      }
    }
  });
}

void _showNormalNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.cancel(911); // إغلاق إشعار الطوارئ
  // إظهار إشعار الخدمة العادي
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'heart_safe_channel',
    'Service',
    importance: Importance.low,
    priority: Priority.low,
  );
  await plugin.show(
    100,
    'الحارس الشخصي نشط 🛡️',
    'أنا أراقب سلامتك الآن...',
    const NotificationDetails(android: androidDetails),
  );
}

// 🔥 النظام الكامل: منقذ بالخلفية + تحول لمصاب عند السقوط

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 🛡️ متغيرات الحالة
  bool isEmergencyMode = false;
  int lastRecordedBpm = 0;
  StreamSubscription? btSubscription;
  bool isBroadcasting = false;
  bool isRescuerMode = true; // 🔑 المفتاح: نبدأ كمنقذ دائماً

  // ══════════════════════════════════════════════════════════
  // 🟢 دالة تشغيل وضع المنقذ (Discovery - دائماً نشط)
  // ══════════════════════════════════════════════════════════
  Future<void> startRescuerMode() async {
    if (isRescuerMode && !isEmergencyMode) return; // لو شغال، ما نعيد

    try {
      print("🔍 بدء وضع المنقذ في الخلفية...");

      // إيقاف أي بث سابق (لو كنا مصابين)
      await Nearby().stopAdvertising().catchError((e) => null);
      await Nearby().stopDiscovery().catchError((e) => null);

      bool started = await Nearby().startDiscovery(
        "Guardian_${Random().nextInt(10000)}",
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, sid) {
          print("🚨 وجدت مصاب: $name");

          if (name.startsWith("VICTIM_")) {
            // 📢 إرسال إشعار فوري للمنقذ
            _showRescuerAlert(id, name);

            // طلب الاتصال لاستقبال البيانات
            Nearby().requestConnection(
              "Guardian",
              id,
              onConnectionInitiated: (id, info) {
                Nearby().acceptConnection(
                  id,
                  onPayLoadRecieved: (endId, payload) {
                    if (payload.type == PayloadType.BYTES &&
                        payload.bytes != null) {
                      try {
                        String jsonData = utf8.decode(payload.bytes!);
                        Map<String, dynamic> victimData = jsonDecode(jsonData);

                        print("📦 بيانات المصاب: $victimData");

                        // إرسال للواجهة
                        service.invoke('victimFound', {
                          'id': id,
                          'lat': victimData['lat'],
                          'lng': victimData['lng'],
                          'bpm': victimData['bpm'],
                        });

                        // تحديث الإشعار بالتفاصيل
                        _showRescuerDetails(victimData);
                      } catch (e) {
                        print("❌ خطأ في فك البيانات: $e");
                      }
                    }
                  },
                );
              },
              onConnectionResult: (id, status) {
                print("🔗 حالة الاتصال: $status");
              },
              onDisconnected: (id) {
                print("❌ انقطع الاتصال مع المصاب");
              },
            );
          }
        },
        onEndpointLost: (id) {
          print("📡 فُقد المصاب: $id");
          service.invoke('victimLost', {'id': id});
        },
        serviceId: "com.example.heart_safe",
      );

      isRescuerMode = started;
      print(started ? "✅ وضع المنقذ نشط" : "❌ فشل تشغيل وضع المنقذ");

      if (service is AndroidServiceInstance && started) {
        service.setForegroundNotificationInfo(
          title: "🛡️ الحارس الشخصي نشط",
          content: "وضع المنقذ: جاهز لاستقبال إشارات SOS",
        );
      }
    } catch (e) {
      print("❌ خطأ في وضع المنقذ: $e");
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🔵 دالة الاتصال بالسوارة (عند السقوط فقط)
  // ══════════════════════════════════════════════════════════
  Future<void> startBackgroundBluetooth(Function(int) onBpmUpdate) async {
    try {
      print("🔍 بدء مسح السوارة...");

      await ble.FlutterBluePlus.stopScan();
      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        androidUsesFineLocation: true,
      );

      btSubscription?.cancel(); // إلغاء أي اشتراك سابق
      btSubscription = ble.FlutterBluePlus.scanResults.listen((results) async {
        for (ble.ScanResult r in results) {
          if (r.device.platformName.contains("HeartSafe")) {
            await ble.FlutterBluePlus.stopScan();
            print("✅ وجدت السوارة");

            try {
              await r.device.connect(timeout: const Duration(seconds: 10));
              var services = await r.device.discoverServices();

              for (var s in services) {
                if (s.uuid.toString().contains("180d")) {
                  for (var c in s.characteristics) {
                    if (c.uuid.toString().contains("2a37")) {
                      await c.setNotifyValue(true);
                      c.lastValueStream.listen((value) {
                        if (value.length > 1 && isEmergencyMode) {
                          // 🔑 فقط لو الطوارئ نشطة
                          int currentBpm = value[1];
                          print("💓 نبض: $currentBpm");
                          onBpmUpdate(currentBpm);
                        }
                      });
                      return;
                    }
                  }
                }
              }
            } catch (e) {
              print("❌ خطأ في الاتصال: $e");
            }
          }
        }
      });
    } catch (e) {
      print("❌ خطأ في البلوتوث: $e");
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🔴 دالة بث SOS (عند السقوط فقط)
  // ══════════════════════════════════════════════════════════
  Future<void> startEmergencyBroadcast() async {
    if (isBroadcasting) return;

    try {
      print("📍 محاولة جلب الموقع في الخلفية...");

      Position? pos;
      try {
        // 1️⃣ محاولة جلب آخر موقع معروف (سريع جداً وموفر للطاقة)
        pos = await Geolocator.getLastKnownPosition();

        // 2️⃣ إذا لم يوجد موقع مخزن، نطلب موقعاً جديداً
        // استخدمنا المعاملات المباشرة لتجنب خطأ 'locationSettings' غير المعرف
        if (pos == null) {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high, // دقة عالية للطوارئ
          ).timeout(const Duration(seconds: 10));
        }
      } catch (e) {
        print("⚠️ خطأ في GPS: $e");
        // في حال فشل الـ GPS تماماً، نضع قيم افتراضية لمنع توقف الكود
      }

      double latitude = pos?.latitude ?? 0.0;
      double longitude = pos?.longitude ?? 0.0;

      print("✅ الموقع المكتشف: $latitude, $longitude");

      // 🔑 إصلاح جوهري: إيقاف "المنقذ" (البحث) لتمكين "المصاب" (البث)
      // لا يمكن لشريحة البلوتوث القيام بالعمليتين معاً بكفاءة عالية في آن واحد
      await Nearby().stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 500));
      isRescuerMode = false;

      String victimName = "VICTIM_${Random().nextInt(10000)}";

      // 📡 بدء بث إشارة SOS باستخدام Nearby Connections
      bool started = await Nearby().startAdvertising(
        victimName,
        Strategy.P2P_STAR,
        onConnectionInitiated: (id, info) {
          // قبول الاتصال تلقائياً لإرسال البيانات للمنقذ القادم
          Nearby().acceptConnection(id, onPayLoadRecieved: (endId, payload) {});
        },
        onConnectionResult: (id, status) async {
          if (status == Status.CONNECTED) {
            // 📦 تجهيز حزمة البيانات (الموقع + نبض القلب الحالي)
            String dataPackage = jsonEncode({
              'lat': latitude,
              'lng': longitude,
              'bpm': lastRecordedBpm, // القيمة المسجلة من السوارة
              'emergency': true,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            // إرسال البيانات فوراً للمنقذ الذي اتصل بنا
            await Nearby().sendBytesPayload(
              id,
              Uint8List.fromList(utf8.encode(dataPackage)),
            );
            print("📤 تم إرسال SOS والبيانات للمنقذ القريب!");
          }
        },
        onDisconnected: (id) => print("❌ انفصل المنقذ"),
        serviceId: "com.example.heart_safe",
      );

      isBroadcasting = started;

      // 📢 تحديث الإشعار في لوحة التنبيهات ليدرك المستخدم أن النظام يعمل
      _showStaticEmergencyNotification(
        lastBpm: lastRecordedBpm,
        status: started
            ? "📡 موقعك ونبضك يُبثان الآن للمنقذين القريبين"
            : "⚠️ فشل البث التلقائي - حاول يدوياً",
      );
    } catch (e) {
      print("❌ خطأ فني فادح في البث: $e");
    }
  }

  // ══════════════════════════════════════════════════════════
  // 🚨 مستمع السقوط (التحول من منقذ → مصاب)
  // ══════════════════════════════════════════════════════════
  userAccelerometerEvents.listen((event) async {
    double acc = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (acc > 32 && !isEmergencyMode) {
      isEmergencyMode = true;
      print("🚨🚨🚨 سقوط! التحول لوضع المصاب...");

      // 1️⃣ إشعار فوري
      service.invoke('triggerEmergency');
      platform.invokeMethod('triggerNativeEmergency').catchError((e) => null);

      _showStaticEmergencyNotification(
        lastBpm: lastRecordedBpm,
        status: "🚨 سقوط! جاري بث الموقع...",
      );

      // 2️⃣ بدء قراءة النبض
      startBackgroundBluetooth((newBpm) {
        lastRecordedBpm = newBpm;
        service.invoke('updateBpmUi', {'bpm': newBpm});

        _showStaticEmergencyNotification(
          lastBpm: newBpm,
          status: "💓 النبض: $newBpm BPM | جاري البث...",
        );
      });

      // 3️⃣ بث SOS بعد ثانيتين
      await Future.delayed(const Duration(seconds: 2));
      startEmergencyBroadcast();
    }
  });

  // ══════════════════════════════════════════════════════════
  // ✅ مستمع "أنا بخير" (التصفير الكامل)
  // ══════════════════════════════════════════════════════════
  service.on('resetEmergency').listen((event) async {
    print("⚡ تصفير: أنا بخير!");

    // 🛑 إيقاف كل شيء
    isEmergencyMode = false;
    isBroadcasting = false;

    btSubscription?.cancel();
    btSubscription = null;

    await ble.FlutterBluePlus.stopScan();
    await Nearby().stopAdvertising();

    // 🗑️ مسح إشعار الطوارئ
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(911);

    // 🔄 العودة لوضع المنقذ
    await Future.delayed(const Duration(seconds: 1));
    startRescuerMode();

    print("✅ تم التصفير والعودة لوضع المنقذ");
  });

  // ══════════════════════════════════════════════════════════
  // 📊 مستمعات أخرى
  // ══════════════════════════════════════════════════════════
  service.on('checkStatus').listen((event) {
    service.invoke('statusResponse', {'isActive': isEmergencyMode});
  });

  service.on('updateBpmData').listen((event) {
    if (event != null && event['bpm'] != null) {
      lastRecordedBpm = event['bpm'];
      service.invoke('updateBpmUi', {'bpm': lastRecordedBpm});
    }
  });

  // 🚀 الانطلاقة: تشغيل وضع المنقذ فوراً
  startRescuerMode();

  print("🎯 النظام جاهز: منقذ في الخلفية + جاهز للتحول لمصاب");
}

// ══════════════════════════════════════════════════════════
// 📢 إشعار الطوارئ (للمصاب)
// ══════════════════════════════════════════════════════════
// Future<void> _showStaticEmergencyNotification({
//   required int lastBpm,
//   required String status,
// }) async {
//   final plugin = FlutterLocalNotificationsPlugin();

//   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'emergency_alert',
//     'Emergency Status',
//     importance: Importance.max,
//     priority: Priority.high,
//     ongoing: true,
//     color: const Color.fromARGB(255, 255, 0, 0),
//     subText: "نظام الحماية نشط 🛡️",
//   );

//   await plugin.show(
//     911,
//     lastBpm > 0 ? '🚨 سقوط! النبض: $lastBpm BPM' : '🚨 تنبيه: تم رصد سقوط!',
//     status,
//     NotificationDetails(android: androidDetails),
//   );
// }

// ══════════════════════════════════════════════════════════
// 🚑 إشعار للمنقذ (اكتشاف مصاب)
// ══════════════════════════════════════════════════════════
Future<void> _showRescuerAlert(String victimId, String victimName) async {
  final plugin = FlutterLocalNotificationsPlugin();

  // 🔊 إعدادات القناة (هذا هو السر في الصوت والاهتزاز)
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'rescuer_emergency_channel', // معرف القناة
    'تنبيهات إنقاذ عاجلة', // اسم القناة للمستخدم
    importance: Importance.max, // أقصى أهمية لظهور الإشعار فوراً
    priority: Priority.high, // أولوية عالية
    enableVibration: true, // تفعيل الاهتزاز
    vibrationPattern: Int64List.fromList([
      0,
      1000,
      500,
      1000,
      500,
      1000,
    ]), // نمط اهتزاز قوي (نبضات)
    playSound: true, // تشغيل صوت
    fullScreenIntent: true, // محاولة فتح الشاشة فوراً
    color: const Color(0xFFFF0000), // لون أحمر للتنبيه
    ledColor: const Color(0xFFFF0000),
    ledOnMs: 1000,
    ledOffMs: 500,
  );

  await plugin.show(
    victimId.hashCode,
    '🚑 مصاب قريب يحتاج مساعدتك!',
    'تم رصد إشارة SOS من $victimName. اضغط للمساعدة!',
    NotificationDetails(android: androidDetails),
    payload: 'victim_$victimId',
  );
}

// ══════════════════════════════════════════════════════════
// 📍 إشعار تفاصيل المصاب (مع الموقع والنبض)
// ══════════════════════════════════════════════════════════
Future<void> _showRescuerDetails(Map<String, dynamic> victimData) async {
  final plugin = FlutterLocalNotificationsPlugin();

  double lat = victimData['lat'];
  double lng = victimData['lng'];
  int bpm = victimData['bpm'] ?? 0;

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'victim_details',
    'Victim Details',
    importance: Importance.max,
    priority: Priority.high,
    color: const Color.fromARGB(255, 255, 0, 0),
    styleInformation: BigTextStyleInformation(
      'النبض: $bpm BPM\nالموقع: $lat, $lng\n\nاضغط لفتح الخريطة',
    ),
  );

  await plugin.show(
    999,
    '📍 بيانات المصاب',
    'النبض: $bpm BPM | اضغط للتوجه',
    NotificationDetails(android: androidDetails),
    payload: 'map_$lat,$lng',
  );
}
// ⚠️ ملاحظة: تم حذف دالة _launchEmergency لأن منطقها أصبح مدمجاً بالأعلى
// لضمان عدم حدوث خطأ "Method not found" مرة أخرى.

// دالة تشغيل الرادار بأمان
void _runRadarSystem(ServiceInstance service) {
  try {
    Nearby().stopAdvertising();
    Nearby().startDiscovery(
      "Guardian",
      Strategy.P2P_CLUSTER,
      onEndpointFound: (id, name, sid) {
        if (name.contains("VICTIM")) {
          service.invoke('victimFound', {'id': id, 'name': name});
        }
      },
      onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
      serviceId: "com.example.heart_safe",
    );
  } catch (e) {}
}

// دالة تشغيل الرادار المحمية
void _safeStartRadar(ServiceInstance service) async {
  try {
    await Nearby().stopAdvertising();
    await Nearby().startDiscovery(
      "Guardian",
      Strategy.P2P_CLUSTER,
      onEndpointFound: (id, name, sid) {
        if (name.startsWith("VICTIM|")) {
          service.invoke('victimFound', {'id': id, 'name': name});
        }
      },
      onEndpointLost: (id) => service.invoke('victimLost', {'id': id}),
      serviceId: "com.example.heart_safe",
    );
    print("📡 الرادار يعمل الآن بصمت في الخلفية...");
  } catch (e) {
    print("Radar Error: $e");
  }
}
// ---------------------------------------------------------
// الدوال المساعدة (تأكد من وجودها أيضاً خارج الكلاسات)
// ---------------------------------------------------------

// دالة تحديث الإشعار بالنبض الحي
// دالة تحديث الإشعار مع إضافة زر التفاعل
Future<void> _showStaticEmergencyNotification({
  required int lastBpm,
  required String status,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'emergency_alert',
    'Emergency Status',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    onlyAlertOnce: false,
    showWhen: true,
    usesChronometer: false,
    color: const Color.fromARGB(255, 255, 0, 0),
    // الـ subText نتركه كمعلومة إضافية بسيطة أو نلغيه
    subText: "نظام الحماية نشط 🛡️",
  );

  // 🚀 التعديل الجوهري هنا:
  // قمنا بدمج منطق النبض داخل "العنوان" لكي يظهر بالخط العريض والواضح
  await plugin.show(
    911,
    lastBpm > 0
        ? '🚨 سقوط! النبض: $lastBpm BPM' // يظهر بخط عريض وواضح جداً
        : '🚨 تنبيه: تم رصد سقوط!', // يظهر في حال عدم توفر نبض
    status,
    NotificationDetails(android: androidDetails),
  );
}

Future<void> _showEmergencyNotification() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // إعدادات الاهتزاز (نمط متكرر مثل المنبه: 0 تأخير، 500 هز، 200 توقف، 500 هز)
  final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'emergency_alert', // يجب أن يطابق ID القناة التي أنشأتها
    'Emergency Notification',
    importance: Importance.max,
    priority: Priority.high,

    // 🚀 السطر السحري: يفتح الـ EmergencyActivity فوراً حتى لو الجوال مقفل
    fullScreenIntent: true,

    // 🚨 تصنيفات تجعل النظام يعطي الأولوية للقفز
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,

    // 🛡️ ضمان الظهور فوق قفل الشاشة
    visibility: NotificationVisibility.public,

    // 🔊 تنبيهات إضافية لضمان الاستيقاظ
    ongoing: true, // يمنع المستخدم من حذفه بسهولة
    vibrationPattern: vibrationPattern,
    enableLights: true,
    color: const Color.fromARGB(255, 255, 0, 0), // لون الإشعار أحمر طوارئ
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    ledOnMs: 1000,
    ledOffMs: 500,

    // نص يظهر في شريط الحالة فور الصدمة
    ticker: '🚨 نجدة طوارئ: تم رصد سقوط عنيف!',
  );

  await flutterLocalNotificationsPlugin.show(
    911,
    '🚨 حالة طوارئ: تم رصد سقوط!',
    'جاري فحص النبض وبث الموقع للمنقذين...',
    NotificationDetails(android: androidDetails),
    payload: 'emergency', // هذا سيتم التقاطه في الـ main لفتح الصفحة الحمراء
  );
}
// ================== واجهات التطبيق ==================

class HeartSafeApp extends StatelessWidget {
  const HeartSafeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Heart Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class EmergencyController {
  static bool isEmergencyActive = false;
  static int currentBpm = 0;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeAppPermissions();
    // 🕵️ الاستجواب الفوري عند فتح التطبيق
    _checkBackgroundEmergencyStatus();
  }

  void _checkBackgroundEmergencyStatus() {
    // نسأل الخدمة: "هل فاتني شيء وأنا مغلق؟"
    FlutterBackgroundService().invoke('checkStatus');

    FlutterBackgroundService().on('statusResponse').listen((event) {
      if (event != null && event['isActive'] == true) {
        // 🚀 وجدنا "ماء" في الخزان! نفتح صفحة الطوارئ فوراً
        if (!EmergencyController.isEmergencyActive) {
          _handleEmergencyJump();
        }
      }
    });
  }

  void _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
      Permission.sensors,
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();
  }

  // 🛠️ دالة تجميع كل التصاريح في مكان واحد
  Future<void> _initializeAppPermissions() async {
    // أولاً: التصاريح العادية (الموقع، البلوتوث، الحساسات)
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.sensors,
    ].request();

    // ثانياً: 🛡️ تصريح "الظهور فوق التطبيقات" (Overlay)
    // هذا هو الكود الذي سألته عنه
    if (await Permission.systemAlertWindow.isDenied) {
      // سنظهر تنبيه بسيط للمستخدم قبل نقله للإعدادات (اختياري لكنه احترافي)
      _showPermissionDialog();
    }
  }

  // دالة طلب تصريح Overlay (التي سألت عنها)
  Future<void> _requestOverlayPermission() async {
    await Permission.systemAlertWindow.request();
  }

  // 📢 حوار توضيحي للمستخدم (لماذا نحتاج هذا التصريح؟)
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🛡️ تفعيل الحماية القصوى"),
        content: const Text(
          "ليتمكن التطبيق من إنقاذك وتنبيهك حتى والشاشة مغلقة، يرجى السماح بـ 'الظهور فوق التطبيقات'.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestOverlayPermission(); // نقل المستخدم للإعدادات
            },
            child: const Text("حسناً، تفعيل"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Heart Safe 🫀',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildBtn(
                  context,
                  Icons.monitor_heart,
                  'فحص النبض',
                  Colors.pink,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HeartRatePage(),
                    ),
                  ),
                ),
                _buildBtn(
                  context,
                  Icons.radar,
                  'وضع المنقذ',
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BroadcastPage(),
                    ),
                  ),
                ),
                _buildBtn(
                  context,
                  Icons.medical_services,
                  'دليل الإنعاش',
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CprGuidePage(),
                    ),
                  ),
                ),
                _buildBtn(
                  context,
                  Icons.info,
                  'حول التطبيق',
                  Colors.orange,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: Colors.green, size: 40),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "الحارس الشخصي نشط",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "نظام رصد السقوط يعمل الآن",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== صفحة الطوارئ الآلية ==================
// ================== صفحة الطوارئ الآلية (النسخة الصافية) ==================

class AutomaticEmergencyPage extends StatefulWidget {
  const AutomaticEmergencyPage({super.key});

  @override
  State<AutomaticEmergencyPage> createState() => _AutomaticEmergencyPageState();
}

class _AutomaticEmergencyPageState extends State<AutomaticEmergencyPage> {
  int bpm = 0;
  String statusMessage = "🚨 جاري بدء رصد النبض..."; // ← تغيير الاسم
  bool isConnected = false;
  StreamSubscription? _scanSubscription;

  // معرف فريد للضحية
  final String myUserName = "Emergency_${Random().nextInt(10000)}";
  final String serviceId = "com.example.heart_safe";
  bool isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    // بدء الإجراءات الطارئة بالترتيب
    Future.delayed(const Duration(milliseconds: 500), () {
      _startEmergencyProtocol();
    });
  }

  // 🚨 بروتوكول الطوارئ الكامل
  void _startEmergencyProtocol() async {
    // 1️⃣ بدء قراءة النبض
    _forcePulseCheck();

    // 2️⃣ الانتظار قليلاً لضمان الحصول على موقع دقيق
    await Future.delayed(const Duration(seconds: 5));

    // 3️⃣ بث الاستغاثة بالتقنية المتطورة
    _broadcastSOSAdvanced();
  }

  // 🛠️ قراءة النبض من السوارة (نفس الكود الناجح)
  void _forcePulseCheck() async {
    try {
      await ble.FlutterBluePlus.stopScan();

      var state = await ble.FlutterBluePlus.adapterState.first;
      if (state != ble.BluetoothAdapterState.on) {
        setState(() => statusMessage = "⚠️ يرجى تفعيل البلوتوث فوراً!");
        return;
      }

      setState(() => statusMessage = "🔍 جاري رصد السوارة الآن...");

      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        androidUsesFineLocation: true,
      );

      _scanSubscription = ble.FlutterBluePlus.scanResults.listen((
        results,
      ) async {
        for (ble.ScanResult r in results) {
          if (r.device.platformName.contains("HeartSafe") && !isConnected) {
            isConnected = true;
            await ble.FlutterBluePlus.stopScan();

            setState(() => statusMessage = "✅ تم الربط! جاري قراءة النبض...");

            try {
              await r.device.connect(timeout: const Duration(seconds: 10));

              var services = await r.device.discoverServices();
              for (var s in services) {
                if (s.uuid.toString().contains("180d")) {
                  for (var c in s.characteristics) {
                    if (c.uuid.toString().contains("2a37")) {
                      await c.setNotifyValue(true);
                      c.lastValueStream.listen((value) async {
                        if (value.length > 1 && mounted) {
                          int newBpm = value[1];
                          setState(() {
                            bpm = newBpm;
                            statusMessage =
                                "🚨 يتم بث نبضك ($bpm BPM) وموقعك للمنقذين";
                          });

                          // حفظ النبض في SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('last_bpm', newBpm);

                          // مزامنة مع الخدمة الخلفية
                          FlutterBackgroundService().invoke('updateBpmData', {
                            'bpm': newBpm,
                          });

                          debugPrint("💾 Emergency BPM saved: $newBpm");
                        }
                      });
                    }
                  }
                }
              }
            } catch (e) {
              isConnected = false;
              debugPrint("❌ Connection error: $e");
              // إعادة محاولة بعد 3 ثواني
              Future.delayed(const Duration(seconds: 3), _forcePulseCheck);
            }
          }
        }
      });
    } catch (e) {
      debugPrint("❌ BT Error: $e");
    }
  }

  // 🚨 بث الاستغاثة بالتقنية المتطورة (Payload-based)
  void _broadcastSOSAdvanced() async {
    if (isBroadcasting) return; // منع البث المزدوج

    try {
      // إيقاف أي بث سابق
      await Nearby().stopAdvertising();
      await Nearby().stopAllEndpoints();

      setState(() => statusMessage = "📍 جاري تحديد موقعك...");

      // الحصول على الموقع الحالي
      Position currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
        "📍 Location obtained: ${currentPos.latitude}, ${currentPos.longitude}",
      );

      // جلب آخر نبض محفوظ
      int lastBpm = bpm;
      if (lastBpm == 0) {
        try {
          final prefs = await SharedPreferences.getInstance();
          lastBpm = prefs.getInt('last_bpm') ?? 72;
        } catch (e) {
          lastBpm = 72;
        }
      }

      debugPrint("🚨 Starting SOS broadcast with BPM: $lastBpm");

      // بدء البث باسم بسيط
      bool started = await Nearby().startAdvertising(
        "VICTIM_$myUserName", // اسم بسيط وقصير
        Strategy.P2P_STAR,
        onConnectionInitiated: (id, info) {
          debugPrint("🤝 Emergency: Connection initiated with rescuer: $id");

          // قبول الاتصال فوراً
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endId, payload) {
              debugPrint("📨 Received message from rescuer");
            },
          );
        },
        onConnectionResult: (id, connectionStatus) async {
          if (connectionStatus == Status.CONNECTED) {
            debugPrint("✅ Emergency: Connected to rescuer: $id");

            // إرسال البيانات الطبية والموقع عبر Payload
            String dataPackage = jsonEncode({
              'lat': currentPos.latitude,
              'lng': currentPos.longitude,
              'bpm': lastBpm,
              'emergency': true, // علامة أن هذه حالة طوارئ
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            await Nearby().sendBytesPayload(
              id,
              Uint8List.fromList(utf8.encode(dataPackage)),
            );

            if (mounted) {
              setState(() => statusMessage = "✅ تم إرسال بياناتك للمنقذ!");
            }

            debugPrint("📡 Emergency data sent successfully");
          } else {
            debugPrint("❌ Connection failed with rescuer: $id");
          }
        },
        onDisconnected: (id) {
          debugPrint("❌ Rescuer disconnected: $id");
          if (mounted) {
            setState(
              () => statusMessage = "⚠️ انقطع الاتصال - جاري إعادة البث...",
            );
          }
        },
        serviceId: serviceId,
      );

      setState(() {
        isBroadcasting = started;
        if (started) {
          statusMessage = "📡 يتم بث موقعك ونبضك ($lastBpm BPM) للمنقذين...";
        } else {
          statusMessage = "❌ فشل البث - جاري إعادة المحاولة...";
          // إعادة المحاولة بعد 3 ثواني
          Future.delayed(const Duration(seconds: 3), _broadcastSOSAdvanced);
        }
      });

      debugPrint(
        started
            ? "✅ SOS broadcast started successfully"
            : "❌ SOS broadcast failed",
      );
    } catch (e) {
      debugPrint("❌ Broadcast error: $e");
      setState(() => statusMessage = "❌ خطأ في البث - جاري إعادة المحاولة...");

      // إعادة المحاولة بعد 5 ثواني
      Future.delayed(const Duration(seconds: 5), _broadcastSOSAdvanced);
    }
  }

  // إيقاف كل شيء عند الخروج
  void _stopEmergency() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopAllEndpoints();
      await ble.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      FlutterBackgroundService().invoke('resetEmergency');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Stop error: $e");
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    ble.FlutterBluePlus.stopScan();
    Nearby().stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة التحذير
                  const Icon(
                    Icons.warning_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),

                  // العنوان
                  const Text(
                    "🚨 حالة طوارئ",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "تم رصد سقوط عنيف",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  // رسالة الحالة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // عرض النبض
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          bpm > 0 ? "$bpm" : "--",
                          style: TextStyle(
                            fontSize: 70,
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "BPM",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // مؤشر البث
                  if (isBroadcasting)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_tethering,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "البث نشط",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),

                  // زر الإيقاف
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.check_circle, size: 28),
                    onPressed: _stopEmergency,
                    label: const Text(
                      "أنا بخير - إيقاف الطوارئ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // معلومات إضافية
                  Text(
                    "يتم بث موقعك تلقائياً للمنقذين القريبين",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================== صفحة المنقذ (الرادار) ==================

class BroadcastPage extends StatefulWidget {
  const BroadcastPage({super.key});

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  bool isVictimMode = false;
  bool isRescuerMode = false;
  String statusMessage = "مختبر البيانات الطبية والمسافة";

  Map<String, Map<String, dynamic>> foundVictims = {};
  StreamSubscription? _positionStream;
  int _currentBpm = 0; // ← تخزين النبض محلياً

  // معرف فريد للمستخدم
  final String myUserName = "User_${Random().nextInt(10000)}";
  final String serviceId = "com.example.heart_safe";

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
    _loadLastBpm(); // ← تحميل آخر نبض مسجل
  }

  // تحميل آخر قيمة نبض من EmergencyController
  void _loadLastBpm() {
    setState(() {
      _currentBpm = EmergencyController.currentBpm;
      // إذا كانت القيمة 0، نستخدم قيمة افتراضية معقولة
      if (_currentBpm == 0) {
        _currentBpm = 72; // معدل نبض طبيعي افتراضي
      }
    });
    debugPrint("📊 Current BPM loaded: $_currentBpm");
  }

  // طلب جميع الأذونات عند بدء الصفحة
  Future<void> _requestAllPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.locationAlways,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ].request();
    }
  }

  // 🛠️ دالة التصفير الصلب
  Future<void> _prepareRadio() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
      _positionStream?.cancel();
      if (mounted) {
        setState(() => foundVictims.clear());
      }
    } catch (e) {
      debugPrint("Cleanup Error: $e");
    }
  }

  // ================== وضع الضحية (Victim Mode) ==================
  void _toggleVictimMode() async {
    await _prepareRadio();

    if (isVictimMode) {
      setState(() {
        isVictimMode = false;
        statusMessage = "توقف البث";
      });
      return;
    }

    // فحص الأذونات أولاً
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    // التحقق من منح جميع الأذونات
    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
      return;
    }

    setState(() => statusMessage = "⏳ جاري تحديد الموقع...");

    try {
      // 1. فحص تفعيل الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => statusMessage = "❌ فعّل GPS من الإعدادات");
        return;
      }

      // 2. الحصول على الموقع الحالي
      Position currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() => statusMessage = "⏳ جاري بدء البث...");
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. جلب آخر نبض محفوظ من SharedPreferences (نفس اللي يستخدمه كود السقوط)
      int lastBpm = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        lastBpm = prefs.getInt('last_bpm') ?? 0;

        // إذا ما لقينا قيمة محفوظة، نحاول من EmergencyController
        if (lastBpm == 0) {
          lastBpm = EmergencyController.currentBpm;
        }

        // إذا ما زال 0، نستخدم قيمة افتراضية
        if (lastBpm == 0) {
          lastBpm = 72; // معدل نبض طبيعي افتراضي
        }
      } catch (e) {
        debugPrint("⚠️ Error loading BPM: $e");
        lastBpm = EmergencyController.currentBpm > 0
            ? EmergencyController.currentBpm
            : 72;
      }

      debugPrint("📡 Broadcasting with BPM: $lastBpm (from SharedPreferences)");

      // 4. بدء البث باسم بسيط (بدون إحداثيات)
      bool started = await Nearby().startAdvertising(
        "VICTIM_$myUserName", // اسم بسيط وقصير
        Strategy.P2P_STAR,
        onConnectionInitiated: (id, info) {
          debugPrint("🤝 Connection initiated with: $id");
          // قبول الاتصال فوراً
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endId, payload) {
              // يمكن استقبال رسائل من المنقذ هنا (اختياري)
            },
          );
        },
        onConnectionResult: (id, status) async {
          if (status == Status.CONNECTED) {
            debugPrint("✅ Connected to rescuer: $id");

            // إرسال البيانات الطبية والموقع عبر Payload
            String dataPackage = jsonEncode({
              'lat': currentPos.latitude,
              'lng': currentPos.longitude,
              'bpm': lastBpm,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            await Nearby().sendBytesPayload(
              id,
              Uint8List.fromList(utf8.encode(dataPackage)),
            );

            if (mounted) {
              setState(() => statusMessage = "📡 تم إرسال البيانات للمنقذ!");
            }
          }
        },
        onDisconnected: (id) {
          debugPrint("❌ Disconnected from: $id");
          if (mounted) {
            setState(() => statusMessage = "⚠️ انقطع الاتصال مع المنقذ");
          }
        },
        serviceId: serviceId,
      );

      setState(() {
        isVictimMode = started;
        isRescuerMode = false;
        statusMessage = started
            ? "📡 تبث الآن: موقعك + نبضك ($lastBpm BPM)"
            : "❌ فشل البث - أعد المحاولة";
      });
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
        errorMsg =
            "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services → تحديث";
      } else if (e.toString().contains('location')) {
        errorMsg = "❌ لم يتم تحديد الموقع - افتح خرائط جوجل مرة";
      } else if (e.toString().contains('BLUETOOTH')) {
        errorMsg = "❌ فعّل Bluetooth و WiFi";
      } else {
        errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
      }
      setState(() => statusMessage = errorMsg);
      debugPrint("🔴 Victim Mode Error: $e");
    }
  }

  // ================== وضع المنقذ (Rescuer Mode) ==================
  void _toggleRescuerMode() async {
    await _prepareRadio();

    if (isRescuerMode) {
      setState(() {
        isRescuerMode = false;
        statusMessage = "توقف الرادار";
      });
      return;
    }

    // فحص الأذونات أولاً
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    // التحقق من منح جميع الأذونات
    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      setState(() => statusMessage = "❌ امنح جميع الأذونات من الإعدادات");
      return;
    }

    setState(() => statusMessage = "⏳ جاري تشغيل الرادار...");
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      bool started = await Nearby().startDiscovery(
        myUserName,
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, sid) {
          debugPrint("🔍 Found endpoint: $name (ID: $id)");

          // التحقق من أن الاسم يبدأ بـ VICTIM
          if (!name.startsWith("VICTIM_")) return;

          // طلب الاتصال فوراً (المفتاح الأساسي!)
          Nearby().requestConnection(
            myUserName,
            id,
            onConnectionInitiated: (id, info) {
              debugPrint("🤝 Connection initiated with: $id");

              // قبول الاتصال واستقبال البيانات
              Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endId, payload) async {
                  if (payload.type == PayloadType.BYTES &&
                      payload.bytes != null) {
                    try {
                      // فك تشفير البيانات
                      String jsonData = utf8.decode(payload.bytes!);
                      Map<String, dynamic> victimData = jsonDecode(jsonData);

                      double vLat = victimData['lat'];
                      double vLng = victimData['lng'];
                      int vBpm = victimData['bpm'] ?? 0;

                      // حساب المسافة الأولية
                      Position myPos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      double dist = Geolocator.distanceBetween(
                        myPos.latitude,
                        myPos.longitude,
                        vLat,
                        vLng,
                      );

                      // حفظ بيانات الضحية
                      if (mounted) {
                        setState(() {
                          foundVictims[id] = {
                            'distance': dist,
                            'lat': vLat,
                            'lng': vLng,
                            'bpm': vBpm,
                            'name': name,
                          };
                        });
                      }

                      // بدء تتبع المسافة الحية
                      _startLiveTracking(id, vLat, vLng);

                      debugPrint(
                        "✅ Victim data received: ${victimData.toString()}",
                      );
                    } catch (e) {
                      debugPrint("❌ Error parsing victim data: $e");
                    }
                  }
                },
              );
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                debugPrint("✅ Successfully connected to victim: $id");
              } else {
                debugPrint("❌ Connection failed with: $id");
              }
            },
            onDisconnected: (id) {
              debugPrint("❌ Victim disconnected: $id");
              if (mounted) {
                setState(() => foundVictims.remove(id));
              }
            },
          );
        },
        onEndpointLost: (id) {
          debugPrint("📡 Endpoint lost: $id");
          if (mounted) {
            setState(() => foundVictims.remove(id));
          }
        },
        serviceId: serviceId,
      );

      setState(() {
        isRescuerMode = started;
        isVictimMode = false;
        statusMessage = started
            ? "🔍 الرادار يستقبل البيانات الطبية..."
            : "❌ فشل الرادار - أعد المحاولة";
      });
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('8038') || e.toString().contains('MISSING')) {
        errorMsg =
            "❌ حدّث Google Play Services\nالإعدادات → التطبيقات → Google Play Services";
      } else if (e.toString().contains('BLUETOOTH')) {
        errorMsg = "❌ فعّل Bluetooth و WiFi";
      } else {
        errorMsg = "❌ خطأ: ${e.toString().split('(').first}";
      }
      setState(() => statusMessage = errorMsg);
      debugPrint("🔴 Rescuer Mode Error: $e");
    }
  }

  // ================== تتبع المسافة الحية ==================
  void _startLiveTracking(String victimId, double vLat, double vLng) {
    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // تحديث كل متر
          ),
        ).listen((myPos) {
          if (mounted && foundVictims.containsKey(victimId)) {
            double newDist = Geolocator.distanceBetween(
              myPos.latitude,
              myPos.longitude,
              vLat,
              vLng,
            );
            setState(() {
              foundVictims[victimId]!['distance'] = newDist;
            });
          }
        });
  }

  // ================== واجهة المستخدم ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("رادار المسافة والنبض"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          _buildTestConsole(),
          Expanded(
            child: foundVictims.isEmpty
                ? _buildEmptyState()
                : _buildVictimsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestConsole() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text(
            statusMessage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _modeButton(
                "بث ضحية",
                Icons.wifi_tethering,
                isVictimMode,
                Colors.red,
                _toggleVictimMode,
              ),
              _modeButton(
                "رادار منقذ",
                Icons.radar,
                isRescuerMode,
                Colors.green,
                _toggleRescuerMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String label,
    IconData icon,
    bool isActive,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(isActive ? Icons.stop : icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.black87 : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildVictimsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: foundVictims.length,
      itemBuilder: (context, index) {
        String id = foundVictims.keys.elementAt(index);
        var data = foundVictims[id]!;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "الحالة الحيوية:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${data['bpm']} BPM",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Text(
                  "${data['distance'].toStringAsFixed(1)} m",
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  "المسافة للوصول",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 5),
                    Text(
                      "${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}",
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRescuerMode ? Icons.radar : Icons.info_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            isRescuerMode
                ? "جاري البحث عن ضحايا..."
                : "لا توجد إشارات نشطة حالياً",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _prepareRadio();
    super.dispose();
  }
}

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  int bpm = 0; // القيمة الحالية للنبض
  bool isConnecting = false;
  String statusMessage = "اضغط على الزر لبدء الفحص";

  // دالة البحث والاتصال بالسوارة
  void _startPulseCheck() async {
    setState(() {
      isConnecting = true;
      statusMessage = "جاري البحث عن السوارة...";
    });

    // بدء مسح البلوتوث لمدة 10 ثوانٍ
    ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    ble.FlutterBluePlus.scanResults.listen((results) async {
      for (ble.ScanResult r in results) {
        // البحث عن السوارة بالاسم المبرمج
        if (r.device.platformName.contains("HeartSafe")) {
          ble.FlutterBluePlus.stopScan();
          setState(
            () => statusMessage = "تم العثور على السوارة! جاري الاتصال...",
          );

          try {
            await r.device.connect();
            var services = await r.device.discoverServices();
            for (var s in services) {
              if (s.uuid.toString().contains("180d")) {
                // خدمة نبض القلب
                for (var c in s.characteristics) {
                  if (c.uuid.toString().contains("2a37")) {
                    // خاصية القياس
                    await c.setNotifyValue(true);
                    c.lastValueStream.listen((value) {
                      if (value.length > 1 && mounted) {
                        setState(() {
                          bpm = value[1]; // تحديث رقم النبض على الشاشة
                          isConnecting = false;
                          statusMessage = "النبض مستقر الآن";
                        });
                      }
                    });
                  }
                }
              }
            }
          } catch (e) {
            setState(() => statusMessage = "فشل الاتصال، حاول مرة أخرى");
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("فحص نبض القلب 💓"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة القلب النابض
            Icon(
              Icons.favorite,
              size: 150,
              color: bpm > 0 ? Colors.red : Colors.grey[300],
            ),
            const SizedBox(height: 20),

            // عرض رقم النبض
            Text(
              bpm > 0 ? "$bpm" : "--",
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const Text(
              "نبضة في الدقيقة (BPM)",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // رسالة الحالة
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 60),

            // زر بدء الفحص اليدوي
            ElevatedButton.icon(
              onPressed: isConnecting ? null : _startPulseCheck,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                isConnecting ? "جاري الاتصال..." : "ابدأ فحص النبض الآن",
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CprGuidePage extends StatefulWidget {
  const CprGuidePage({super.key});

  @override
  State<CprGuidePage> createState() => _CprGuidePageState();
}

class _CprGuidePageState extends State<CprGuidePage> {
  final FlutterTts _tts = FlutterTts();
  int _currentStep = 0;

  // قائمة الخطوات باستخدام الصور المحلية (التي أضفتها في الـ assets)
  final List<Map<String, String>> _cprSteps = [
    {
      "title": "تأكد من الأمان",
      "desc":
          "تأكد أن المكان آمن لك وللمصاب قبل البدء. ابحث عن أي مخاطر مثل الكهرباء أو حركة المرور.",
      "voice": "تأكد أولاً من أمان الموقع قبل الاقتراب من المصاب",
      "image": "assets/images/step1.png",
    },
    {
      "title": "افحص الاستجابة",
      "desc":
          "هز كتفي المصاب وناده بصوت عالٍ: هل أنت بخير؟ ابحث عن أي حركة أو تنفس.",
      "voice": "افحص استجابة المصاب، قم بهز كتفيه والمناداة عليه بصوت عال",
      "image": "assets/images/step2.png",
    },
    {
      "title": "اتصل بالإسعاف (997)",
      "desc":
          "إذا لم يستجب، اطلب المساعدة فوراً. اتصل بالرقم 997 وحدد موقعك بدقة.",
      "voice": "المصاب لا يستجيب، اتصل بالإسعاف فوراً على الرقم تسعة تسعة سبعة",
      "image": "assets/images/step3.png",
    },
    {
      "title": "ابدأ ضغطات الصدر",
      "desc":
          "ضع كعب يدك في منتصف الصدر. اضغط بقوة وسرعة (100-120 ضغطة في الدقيقة).",
      "voice": "ضع كعب يدك في منتصف الصدر، وابدأ بالضغط بقوة وسرعة",
      "image": "assets/images/step4.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // إعدادات الصوت للأوفلاين
    await _tts.setLanguage("ar");
    await _tts.setSpeechRate(0.5); // سرعة النطق
    await _tts.setVolume(1.0); // أعلى مستوى صوت

    // نطق الخطوة الأولى عند الدخول
    _speakStep(0);
  }

  void _speakStep(int index) async {
    await _tts.stop();
    await _tts.speak(_cprSteps[index]['voice']!);
  }

  @override
  void dispose() {
    _tts.stop(); // إيقاف الصوت عند الخروج
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("دليل الإنعاش CPR"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          // شريط التقدم العلوي
          LinearProgressIndicator(
            value: (_currentStep + 1) / _cprSteps.length,
            color: Colors.green,
            backgroundColor: Colors.grey[200],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // عرض الصورة المحلية
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _cprSteps[_currentStep]['image']!,
                          fit: BoxFit.contain,
                          // إذا الصورة مو موجودة بيطلع أيقونة بدل الخطأ
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.medical_services,
                                size: 100,
                                color: Colors.red,
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    _cprSteps[_currentStep]['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _cprSteps[_currentStep]['desc']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // أزرار التحكم
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentStep > 0
                    ? TextButton(
                        onPressed: () {
                          setState(() => _currentStep--);
                          _speakStep(_currentStep);
                        },
                        child: const Text("السابق"),
                      )
                    : const SizedBox(width: 60),

                // زر إعادة الصوت
                FloatingActionButton(
                  onPressed: () => _speakStep(_currentStep),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.volume_up, color: Colors.white),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < _cprSteps.length - 1) {
                      setState(() => _currentStep++);
                      _speakStep(_currentStep);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    _currentStep == _cprSteps.length - 1 ? "إنهاء" : "التالي",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
