import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/models/service.dart';
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/utils/rule_engine.dart';
import 'package:motor_care/screens/service/notification_service.dart';

// IMPORT HALAMAN NAVIGASI
import 'package:motor_care/screens/service/service_list_screen.dart';
import 'package:motor_care/screens/service/service_form_screen.dart';
import 'package:motor_care/screens/service/riwayat_screen.dart'; 
import 'package:motor_care/screens/motor/motor_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _motorRepo = MotorRepository();
  final _serviceRepo = ServiceRepository();
  
  bool _isLoading = true;
  
  // STATE BARU UNTUK FITUR PILIH MOTOR
  List<Motor> _allMotors = []; 
  int? _selectedMotorId; 
  
  int _totalMotor = 0;
  Motor? _activeMotor;
  RuleResult? _ruleResult;
  
  int _jadwalMendatangCount = 0;
  int _riwayatServiceCount = 0;
  ServiceModel? _jadwalBerikutnya;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final motors = await _motorRepo.getMotors();
    final allServices = await _serviceRepo.getServices();

    if (motors.isNotEmpty) {
      _allMotors = motors;
      
      // LOGIKA PEMILIHAN MOTOR AKTIF
      Motor active;
      if (_selectedMotorId != null && motors.any((m) => m.id == _selectedMotorId)) {
        active = motors.firstWhere((m) => m.id == _selectedMotorId);
      } else {
        active = motors.first; // Default ke motor pertama jika belum ada yang dipilih
        _selectedMotorId = active.id;
      }
      
      final services = allServices.where((s) => s.motorId == active.id).toList();
      services.sort((a, b) => b.tanggalService.compareTo(a.tanggalService));
      
      final hasil = RuleEngine.evaluasi(active, services);

      // Trigger Notifikasi (Hanya aktif jika demo berjalan)
      if (hasil.jumlahTerlambat > 0) {
        final notifService = NotificationService();
        await notifService.init();
        
        await notifService.showInstantNotification(
          id: active.id!, 
          title: '⚠️ Waktunya Servis!',
          body: 'Ada ${hasil.jumlahTerlambat} komponen yang terlambat diservis pada ${active.namaMotor}.',
        );
      }

      final jadwalMendatang = services.where((s) => s.status == 'Upcoming').toList();
      jadwalMendatang.sort((a, b) => a.tanggalService.compareTo(b.tanggalService));

      setState(() {
        _totalMotor = motors.length;
        _activeMotor = active;
        _ruleResult = hasil;
        _jadwalMendatangCount = jadwalMendatang.length;
        _riwayatServiceCount = services.where((s) => s.status == 'Done').length;
        _jadwalBerikutnya = jadwalMendatang.isNotEmpty ? jadwalMendatang.first : null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _allMotors = [];
        _totalMotor = 0;
        _activeMotor = null;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    if (status == 'Kritis') return CupertinoColors.destructiveRed;
    if (status == 'Perlu Servis') return CupertinoColors.systemOrange;
    return CupertinoColors.activeGreen;
  }

  // FITUR BARU: Menampilkan Bottom Sheet untuk Memilih Motor
  void _showMotorSelectionSheet() {
    if (_allMotors.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Pilih Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ..._allMotors.map((motor) {
                final isActive = motor.id == _selectedMotorId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.two_wheeler, color: isActive ? Colors.blue : Colors.grey),
                  ),
                  title: Text('${motor.merk} ${motor.namaMotor}', style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(motor.nomorPolisi),
                  trailing: isActive ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.blue) : null,
                  onTap: () {
                    Navigator.pop(context); // Tutup menu
                    if (!isActive) {
                      setState(() {
                        _isLoading = true; // Munculkan loading sebentar
                        _selectedMotorId = motor.id; // Ubah ID motor terpilih
                      });
                      _loadData(); // Muat ulang seluruh data berdasarkan motor baru
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      }
    );
  }

  void _showRekomendasiSheet() {
    if (_ruleResult == null || _activeMotor == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekomendasi Perawatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._ruleResult!.rekomendasi.map((rule) {
                final isAman = _ruleResult!.jumlahTerlambat == 0;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isAman ? CupertinoIcons.check_mark : CupertinoIcons.circle_fill, 
                    size: 14, 
                    color: isAman ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed
                  ),
                  title: Text(rule, style: const TextStyle(fontSize: 14)),
                  trailing: isAman ? null : const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                  onTap: isAman ? null : () async {
                    Navigator.pop(context);
                    String jenisKomponen = rule;
                    if (rule.contains(':')) {
                      jenisKomponen = rule.split(':')[0].trim();
                    }
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceFormScreen(
                          prefilledMotorId: _activeMotor!.id,
                          prefilledJenisService: jenisKomponen,
                        ),
                      ),
                    );
                    if (result == true) _loadData();
                  },
                );
              }).toList(),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: EdgeInsets.only(top: statusBarHeight + 20, left: 24, right: 24, bottom: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B71F3),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Selamat Datang', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Indra', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    // FITUR BARU: LOGO PROFIL BISA DIKLIK
                    GestureDetector(
                      onTap: () {
                        // Aksi saat logo profil diklik
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka Halaman Profil...')));
                        // Nanti bisa diganti dengan: Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.person, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),

              // KARTU MOTOR AKTIF (SEKARANG BISA DIKLIK)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _showMotorSelectionSheet, // Panggil pop-up pilih motor
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1.5), // Garis biru tipis menandakan bisa diklik
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('Motor Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  // Ikon panah bawah menandakan *dropdown*
                                  Icon(CupertinoIcons.chevron_down, size: 16, color: Colors.grey.shade600),
                                ],
                              ),
                              Icon(Icons.two_wheeler, color: Colors.blue[700], size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_activeMotor != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMotorInfo('Model', _activeMotor!.namaMotor),
                                _buildMotorInfo('Merek', _activeMotor!.merk),
                                _buildMotorInfo('Plat', _activeMotor!.nomorPolisi),
                              ],
                            )
                          else
                            const Text('Belum ada data motor', style: TextStyle(color: Colors.grey)),
                          
                          const SizedBox(height: 16),
                          Text('Total Motor: $_totalMotor', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // KARTU STATUS KENDARAAN
              if (_activeMotor != null && _ruleResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status Kendaraan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                _ruleResult!.statusAkhir,
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_ruleResult!.statusAkhir),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        _buildStatusMenu(
                          icon: CupertinoIcons.calendar_today,
                          iconColor: Colors.blue,
                          title: 'Jadwal Mendatang',
                          value: '$_jadwalMendatangCount jadwal',
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiceListScreen()));
                          }
                        ),
                        _buildStatusMenu(
                          icon: CupertinoIcons.exclamationmark_triangle,
                          iconColor: Colors.red,
                          title: 'Service Terlambat',
                          value: '${_ruleResult!.jumlahTerlambat} service', 
                          onTap: _showRekomendasiSheet,
                        ),
                        _buildStatusMenu(
                          icon: Icons.history,
                          iconColor: Colors.green,
                          title: 'Riwayat Service',
                          value: '$_riwayatServiceCount service',
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatScreen()));
                          }
                        ),

                        const Divider(height: 1, indent: 20, endIndent: 20),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jadwal Berikutnya', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                _jadwalBerikutnya != null 
                                  ? '${_jadwalBerikutnya!.jenisService} (${_jadwalBerikutnya!.tanggalService})'
                                  : 'Belum ada jadwal service',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 32),

              const Center(
                child: Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), 
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.25, 
                  children: [
                    _buildGridMenuButton(
                      icon: Icons.two_wheeler,
                      title: 'Data Motor',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const MotorListScreen()));
                      },
                    ),
                    _buildGridMenuButton(
                      icon: CupertinoIcons.calendar,
                      title: 'Jadwal Servis',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiceListScreen()));
                      },
                    ),
                    _buildGridMenuButton(
                      icon: Icons.history,
                      title: 'Riwayat Servis',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatScreen()));
                      },
                    ),
                    _buildGridMenuButton(
                      icon: CupertinoIcons.bell,
                      title: 'Notifikasi',
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka halaman Notifikasi')));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotorInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusMenu({required IconData icon, required Color iconColor, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildGridMenuButton({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF3B71F3)), 
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}