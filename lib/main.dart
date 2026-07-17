import 'package:flutter/material.dart';
import 'package:motor_care/screens/home/main_screen.dart';
// Ubah baris ini agar mengarah ke folder screens/service
import 'package:motor_care/screens/service/notification_service.dart'; 

// Ubah main() menjadi async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Panggil inisialisasi notifikasi
  await NotificationService().init();
  
  runApp(const MotorCareApp());
}

class MotorCareApp extends StatelessWidget {
  const MotorCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}