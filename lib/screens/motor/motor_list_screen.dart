import 'package:flutter/material.dart';
import '../../models/motor.dart';
import '../../repositories/motor_repository.dart';
import 'motor_form_screen.dart';

class MotorListScreen extends StatefulWidget {
  const MotorListScreen({super.key});

  @override
  State<MotorListScreen> createState() => _MotorListScreenState();
}

// Pastikan ada <MotorListScreen>
class _MotorListScreenState extends State<MotorListScreen> {
  final MotorRepository _motorRepo = MotorRepository();
  List<Motor> _motors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMotors();
  }

  Future<void> _loadMotors() async {
    setState(() => _isLoading = true);
    final motors = await _motorRepo.getMotors();
    setState(() {
      _motors = motors;
      _isLoading = false;
    });
  }

  Future<void> _hapusMotor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus motor ini? Semua riwayat servicenya akan ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _motorRepo.deleteMotor(id);
      _loadMotors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motor berhasil dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Motor Saya'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _motors.isEmpty
              ? const Center(child: Text('Belum ada data motor. Silakan tambah.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _motors.length,
                  itemBuilder: (context, index) {
                    final motor = _motors[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.motorcycle),
                        ),
                        title: Text('${motor.merk} ${motor.namaMotor}'),
                        subtitle: Text('Plat: ${motor.nomorPolisi} • Km: ${motor.kilometerSaatIni}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MotorFormScreen(motor: motor)),
                                );
                                if (result == true) _loadMotors();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusMotor(motor.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MotorFormScreen()),
          );
          if (result == true) _loadMotors();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}