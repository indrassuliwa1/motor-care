import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/screens/motor/motor_form_screen.dart';

class MotorListScreen extends StatefulWidget {
  const MotorListScreen({super.key});

  @override
  State<MotorListScreen> createState() => _MotorListScreenState();
}

class _MotorListScreenState extends State<MotorListScreen> {
  final _motorRepo = MotorRepository();
  List<Motor> _motors = [];
  bool _isLoading = true;

  final Color _darkBlue = const Color(0xFF305B85); 
  final Color _lightBlue = const Color(0xFFD6E4FF);

  @override
  void initState() {
    super.initState();
    _loadMotors();
  }

  Future<void> _loadMotors() async {
    final motors = await _motorRepo.getMotors();
    setState(() {
      _motors = motors;
      _isLoading = false;
    });
  }

  Future<void> _hapusMotor(int id) async {
    // Tampilkan dialog konfirmasi sebelum menghapus
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan?'),
        content: const Text('Semua riwayat dan jadwal servis untuk motor ini mungkin akan ikut terpengaruh. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _motorRepo.deleteMotor(id);
      _loadMotors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data motor berhasil dihapus'), backgroundColor: CupertinoColors.destructiveRed),
        );
      }
    }
  }

  Future<void> _goToForm([Motor? motor]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MotorFormScreen(motor: motor)),
    );
    if (result == true) _loadMotors();
  }

  // WIDGET KHUSUS: Tampilan saat Data Motor Kosong
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.two_wheeler, size: 100, color: _darkBlue),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Data Motor',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tambahkan profil kendaraanmu di sini untuk mulai memonitor jadwal perawatannya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => _goToForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Motor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
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
        title: const Text('Data Motor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      
      floatingActionButton: _motors.isEmpty ? null : FloatingActionButton.extended(
        backgroundColor: _lightBlue,
        elevation: 2,
        onPressed: () => _goToForm(),
        icon: Icon(Icons.add, color: _darkBlue),
        label: Text('Tambah Motor', style: TextStyle(color: _darkBlue, fontWeight: FontWeight.bold)),
      ),
      
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _motors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: _motors.length,
                  itemBuilder: (context, index) {
                    final motor = _motors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.directions_bike, color: _darkBlue),
                        ),
                        title: Text('${motor.merk} ${motor.namaMotor}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.car_detailed, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(motor.nomorPolisi, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.speedometer, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${motor.kilometerSaatIni} KM (Tahun ${motor.tahun})', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                          onPressed: () => _hapusMotor(motor.id!),
                        ),
                        onTap: () => _goToForm(motor),
                      ),
                    );
                  },
                ),
    );
  }
}