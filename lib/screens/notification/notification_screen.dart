import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/utils/rule_engine.dart';
import 'package:motor_care/screens/service/service_form_screen.dart';

// Class bantuan untuk menampung list notifikasi gabungan
class AlertItem {
  final String title;
  final String description;
  final bool isWarning; // true untuk peringatan terlambat, false untuk jadwal biasa
  final int? motorId;
  final String? ruleKeyword;

  AlertItem({required this.title, required this.description, required this.isWarning, this.motorId, this.ruleKeyword});
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _motorRepo = MotorRepository();
  final _serviceRepo = ServiceRepository();
  
  bool _isLoading = true;
  List<AlertItem> _alerts = [];

  final Color _darkBlue = const Color(0xFF305B85); 

  @override
  void initState() {
    super.initState();
    _generateAlerts();
  }

  Future<void> _generateAlerts() async {
    final motors = await _motorRepo.getMotors();
    final allServices = await _serviceRepo.getServices();
    List<AlertItem> tempAlerts = [];

    for (var motor in motors) {
      final motorServices = allServices.where((s) => s.motorId == motor.id).toList();
      
      // 1. Ambil Peringatan Kritis dari Rule Engine
      final ruleResult = RuleEngine.evaluasi(motor, motorServices);
      for (var rekomendasi in ruleResult.rekomendasi) {
        if (ruleResult.jumlahTerlambat > 0 && !rekomendasi.contains('Aman')) {
          tempAlerts.add(
            AlertItem(
              title: 'Peringatan: ${motor.namaMotor}',
              description: rekomendasi,
              isWarning: true,
              motorId: motor.id,
              ruleKeyword: rekomendasi.split(':')[0], // Mengambil kata kunci sblm titik dua
            )
          );
        }
      }

      // 2. Ambil Jadwal Mendatang dari SQLite
      final upcoming = motorServices.where((s) => s.status == 'Upcoming').toList();
      for (var jadwal in upcoming) {
        tempAlerts.add(
          AlertItem(
            title: 'Jadwal Servis: ${motor.namaMotor}',
            description: 'Jadwal ${jadwal.jenisService} pada tanggal ${jadwal.tanggalService}.',
            isWarning: false,
          )
        );
      }
    }

    setState(() {
      _alerts = tempAlerts;
      _isLoading = false;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bell_slash, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kondisi kendaraanmu sedang aman',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: alert.isWarning ? Colors.red.shade100 : Colors.blue.shade100,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: alert.isWarning ? Colors.red.shade50 : _darkBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            alert.isWarning ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.calendar, 
                            color: alert.isWarning ? CupertinoColors.destructiveRed : _darkBlue,
                          ),
                        ),
                        title: Text(
                          alert.title, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            color: alert.isWarning ? CupertinoColors.destructiveRed : Colors.black87,
                          )
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(alert.description, style: const TextStyle(color: Colors.black54, height: 1.3)),
                        ),
                        trailing: alert.isWarning ? const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey) : null,
                        onTap: alert.isWarning ? () async {
                          // Jika peringatan diklik, langsung arahkan ke Form Servis!
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceFormScreen(
                                prefilledMotorId: alert.motorId,
                                prefilledJenisService: alert.ruleKeyword,
                              ),
                            ),
                          );
                          _generateAlerts(); // Refresh setelah kembali
                        } : null,
                      ),
                    );
                  },
                ),
    );
  }
}