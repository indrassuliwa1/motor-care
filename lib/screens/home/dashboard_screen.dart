import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/utils/rule_engine.dart'; 
// Pastikan import form service dimasukkan ke sini:
import 'package:motor_care/screens/service/service_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _motorRepo = MotorRepository();
  final _serviceRepo = ServiceRepository(); 
  
  List<Motor> _motors = [];
  Map<int, RuleResult> _hasilEvaluasi = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final motors = await _motorRepo.getMotors();
    Map<int, RuleResult> evaluasiMap = {};
    
    final semuaServices = await _serviceRepo.getServices();

    for (var motor in motors) {
      // 1. Ambil HANYA servis untuk motor ini
      final services = semuaServices.where((s) => s.motorId == motor.id).toList();
      
      // 2. URUTKAN dari tanggal terbaru ke paling lama.
      // Hal ini wajib agar RuleEngine.firstWhere() mendapatkan servis yang paling baru!
      services.sort((a, b) => b.tanggalService.compareTo(a.tanggalService));
      
      // 3. Masukkan motor beserta SELURUH riwayat servisnya ke Rule Engine
      final hasil = RuleEngine.evaluasi(motor, services);
      evaluasiMap[motor.id!] = hasil;
    }

    setState(() {
      _motors = motors;
      _hasilEvaluasi = evaluasiMap;
      _isLoading = false;
    });
  }
  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Kritis':
        return CupertinoColors.destructiveRed;
      case 'Perlu Perhatian':
      case 'Perlu Servis':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.activeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalButuhServis = _hasilEvaluasi.values.where((r) => r.statusAkhir != 'Baik').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Care Dashboard'),
      ),
      body: _isLoading 
        ? const Center(child: CupertinoActivityIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildSummaryCard('Total Motor', _motors.length.toString(), CupertinoIcons.car_detailed, CupertinoColors.activeBlue),
                    _buildSummaryCard(
                      'Butuh Servis', 
                      totalButuhServis.toString(), 
                      totalButuhServis > 0 ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.check_mark_circled_solid, 
                      totalButuhServis > 0 ? CupertinoColors.systemOrange : CupertinoColors.activeGreen
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('STATUS KENDARAAN (RULE-BASED)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                if (_motors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('Belum ada data motor untuk dianalisis.', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ..._motors.map((motor) {
                    final evaluasi = _hasilEvaluasi[motor.id]!;
                    final statusColor = _getColorForStatus(evaluasi.statusAkhir);
                    final isAman = evaluasi.statusAkhir == 'Baik';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: Icon(
                          isAman ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.wrench_fill, 
                          color: statusColor,
                          size: 32,
                        ),
                        title: Text('${motor.merk} ${motor.namaMotor}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KM Saat Ini: ${motor.kilometerSaatIni}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Status: ${evaluasi.statusAkhir}', 
                                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                        // MODIFIKASI: Mengubah List Rekomendasi Menjadi Tombol Klik
                        children: evaluasi.rekomendasi.map((rule) {
                          return ListTile(
                            leading: Icon(
                              isAman ? CupertinoIcons.check_mark : CupertinoIcons.circle_fill, 
                              size: 12, 
                              color: isAman ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed
                            ),
                            title: Text(rule, style: const TextStyle(fontSize: 13)),
                            // Menambahkan ikon tanda panah ke kanan jika tidak dalam status "Baik"
                            trailing: isAman ? null : const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                            
                            // Aksi saat diklik
                            onTap: isAman ? null : () async {
                              // Memotong teks, misalnya dari "Kampas Rem: Periksa Ketebalan" -> "Kampas Rem"
                              String jenisKomponen = rule;
                              if (rule.contains(':')) {
                                jenisKomponen = rule.split(':')[0].trim();
                              }

                              // Berpindah ke Form Service dengan membawa data titipan
                              final bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceFormScreen(
                                    prefilledMotorId: motor.id,
                                    prefilledJenisService: 'Servis $jenisKomponen',
                                  ),
                                ),
                              );

                              // Jika form service disimpan (result == true), refresh dashboard
                              if (result == true) {
                                _loadData();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            ),
          ),
    );
  }
}