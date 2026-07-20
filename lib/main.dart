import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:motor_care/screens/home/main_screen.dart';

// IMPORT REPOSITORY & UTILS
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/utils/rule_engine.dart';
import 'package:motor_care/screens/service/notification_service.dart';

// IMPORT SCREEN UTAMA (Sesuaikan jika nama file/foldermu berbeda)
import 'package:motor_care/screens/home/dashboard_screen.dart'; 

// ============================================================================
// FUNGSI BACKGROUND (Wajib diletakkan di luar class dan menggunakan @pragma)
// ============================================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Inisialisasi Ulang Service & Database di dalam Isolate Background
      final motorRepo = MotorRepository();
      final serviceRepo = ServiceRepository();
      final notifService = NotificationService();
      await notifService.init();

      // 2. Ambil semua data motor dari SQLite
      final motors = await motorRepo.getMotors();
      final allServices = await serviceRepo.getServices();

      // 3. Evaluasi Rule Engine untuk setiap motor secara diam-diam
      for (var motor in motors) {
        final motorServices = allServices.where((s) => s.motorId == motor.id).toList();
        motorServices.sort((a, b) => b.tanggalService.compareTo(a.tanggalService));
        
        final hasil = RuleEngine.evaluasi(motor, motorServices);

        // 4. Jika ada komponen terlambat, TEMBAKKAN NOTIFIKASI!
        if (hasil.jumlahTerlambat > 0) {
          await notifService.showInstantNotification(
            id: motor.id!, 
            title: '⚠️ Peringatan: ${motor.namaMotor}!',
            body: 'Ada ${hasil.jumlahTerlambat} komponen terlambat (seperti ${hasil.rekomendasi.first.split(':')[0]}). Cek aplikasi sekarang!',
          );
        }
      }
      return Future.value(true); // Berhasil
    } catch (e) {
      return Future.value(false); // Gagal
    }
  });
}
// ============================================================================

void main() async {
  // Pastikan core Flutter sudah siap sebelum inisialisasi background task
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Workmanager
  await Workmanager().initialize(
    callbackDispatcher, 
    isInDebugMode: false, // Ubah ke true jika ingin melihat log saat testing
  );

  // Mendaftarkan tugas periodik (Misal: Cek kondisi motor setiap 24 jam)
  // Mendaftarkan tugas periodik
  await Workmanager().registerPeriodicTask(
    "cek_rutin_motocare", 
    "cekServisBackground", 
    frequency: const Duration(hours: 24), 
    // TAMBAHKAN KATA "Periodic" DI BAWAH INI
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, 
  );

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
        primaryColor: const Color(0xFF3B71F3),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto', // Bisa disesuaikan
      ),
      home: const MainScreen(), // Sesuaikan dengan nama class di main_screen.dart kamu // Pastikan ini mengarah ke file Dashboard-mu
    );
  }
}