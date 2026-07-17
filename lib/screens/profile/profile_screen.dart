import 'package:flutter/material.dart';
import 'package:motor_care/database/db_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future _resetDatabase(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text('PERINGATAN: Semua data motor dan riwayat service akan dihapus permanen! Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Ya, Reset', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DBHelper().database;
      // Menghapus isi seluruh tabel
      await db.delete('notification');
      await db.delete('service');
      await db.delete('motor');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database berhasil direset! Silakan restart aplikasi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Pengguna Motor Care', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Tentang Aplikasi'),
            subtitle: Text('Motor Care adalah aplikasi Rule-Based untuk memonitor perawatan sepeda motor secara offline.'),
          ),
          const ListTile(
            leading: Icon(Icons.developer_mode),
            title: Text('Tentang Developer'),
            subtitle: Text('Dikembangkan untuk Proyek Skripsi'),
          ),
          const ListTile(
            leading: Icon(Icons.verified),
            title: Text('Versi'),
            subtitle: Text('1.0.0 (MVP Stable)'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Database', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Hapus seluruh data motor dan service'),
            onTap: () => _resetDatabase(context),
          ),
        ],
      ),
    );
  }
}